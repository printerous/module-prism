module Prism
  class Calculator::CorrugatedCalculator
    BLEED = 0 # millimeter
    FLUTING    = { single: 4, double: 6 }.with_indifferent_access   # FLUTING
    ADDITIONAL = { single: 35, double: 40 }.with_indifferent_access # KUPING

    attr_reader   :params, :product_type_id, :quantity, :breakdowns, :printing_type
    attr_accessor :prices, :errors, :total

    # params
    # - product_type_id
    # - quantity
    # - [partner_id]
    # - printing_type
    # - spec: { spec_key: value|spec_value.id }
    # - box_size: { width: value, length: value, height: value } --> CUSTOM BOX SIZE in mm

    def initialize(params)
      @params          = params.with_indifferent_access
      @product_type_id = params[:product_type_id]
      @quantity        = params[:quantity].to_f
      @partners        = Partner.where(id: [ params[:partner_id] ].flatten)

      @printing_type   = params[:printing_type] || :digital
      @calculator      = Prism::ProductCalculator.find_by(code: @printing_type)
      @breakdowns      = @calculator.product_calculator_breakdowns.order(position: :asc)
      @prices          = []
      @errors          = []
    end

    def calculate
      if @quantity.zero?
        @errors << "[#{printing_type}] Jumlah hasil jadi (Quantity) tidak boleh kosong. Mohon isi terlebih dahulu data yang dibutuhkan"
        Rails.logger.info "#{@errors}"
        return @prices
      end

      @partners.each do |partner|
        Rails.logger.info "*" * 100
        Rails.logger.info "== PARTNER #{ partner.name } =="

        machines = partner.active_printing_machines.corrugateds.order("properties -> 'position' ASC").uniq
        if machines.blank?
          @errors << "[#{printing_type}] Tidak ada Mesin yang aktif"
          Rails.logger.info "#{@errors}"
          next
        end

        machines.each do |machine|
          paper             = PrintingPaper.find_by(code: 'corrugated')
          impose_count      = 1
          material_quantity = 1

          @prices << result = {
            partner:                 partner,
            partner_id:              partner.id,
            machine:                 machine,
            machine_id:              machine.id,

            paper:                   paper,
            paper_id:                paper.id,

            quantity:                quantity,
            length:                  length,
            width:                   width,
            print_side:              print_side,
            print_color:             print_color,

            hours:                   0,

            impose_quantity:         impose_count,
            material_quantity:       material_quantity
          }.with_indifferent_access

          @total = 0
          @breakdowns.each do |breakdown|
            formula_klass = breakdown.module_formula.constantize
            formula       = formula_klass.new(breakdown: breakdown, product: self, partner: partner, machine: machine, paper: paper)
            value         = formula.calculate

            Rails.logger.info "---------------------- #{breakdown.module_formula} : #{ partner.name }------------------"
            Rails.logger.info "-------------------------- #{value} --------------------------"

            if value == -1
              @errors << formula.error rescue "[#{printing_type}] Gagal Menghitung <b>#{breakdown.name}</b>. Mohon isi terlebih dahulu data yang dibutuhkan"
              break
            end

            self.total += value
          end

          @errors.flatten!
          result[:price] = self.total / quantity.to_f
          result[:total] = self.total
        end
      end

      @prices.sort! {|a, b| [a[:total]] <=> [b[:total]] }
    end

    def spec
      @spec ||= begin
        Hash[
          params[:spec].to_h.map {|k, v|
            [
              SpecKey.find(k).code,
              SpecKey.find(k).properties['is_direct'] == 1 ? v : SpecValue.find_by(id: v).try(:name)
            ]
          }
        ].with_indifferent_access
      end
    end

    def _spec
      @_spec ||= params[:spec].to_h.with_indifferent_access
    end

    def print_side
      @print_side ||= begin
        key        = SpecKey.find_by(id: @calculator.properties['print_side_id'])
        key_2      = SpecKey.find_by(code: 'printside')

        value_id   = self._spec[key.id.to_s] || self._spec[key_2.id.to_s]
        print_side = SpecValue.find_by(id: value_id)

        print_side&.properties['side']&.to_i || 1
      end
    end

    def print_color
      @print_color ||= colors.max
    end

    def colors
      @colors ||= begin
        key     = SpecKey.find_by(id: @calculator.properties['print_color_a'])
        color_a = self._spec[key.id.to_s].try(:to_i)

        key     = SpecKey.find_by(id: @calculator.properties['print_color_b'])
        color_b = self._spec[key.id.to_s].try(:to_i) || 0

        [ color_a, color_b ]
      end
    end

    def dimension
      @dimension ||= if params[:box_size].blank?
        key      = SpecKey.find_by(id: @calculator.properties['size_id']) ||
                   SpecKey.find_by(code: 'ukuranprodukjadi')

        value_id = self._spec[key.id.to_s]
        size     = SpecValue.find_by(id: value_id) || SpecValue.new

        width    = size&.properties['width_in_mm']&.to_f || 0
        length   = size&.properties['length_in_mm']&.to_f || 0
        height   = size&.properties['height_in_mm']&.to_f || 0
        {
          width: width,
          length: length,
          height: height
        }
      else
        {
          width: params[:box_size][:width]&.to_f,
          length: params[:box_size][:length]&.to_f,
          height: params[:box_size][:height]&.to_f
        }
      end
    end

    def print_area
      @print_area ||= if params[:print_area].present?
        {
          width: params[:print_area][:width]&.to_f / 10.to_f,
          length: params[:print_area][:length]&.to_f / 10.to_f
        }
      else
        {}
      end
    end

    def print_area_value
      @print_area_value ||= begin
        key      = SpecKey.find_by(id: :areacetak)
        value_id = self._spec[key.id.to_s]
        SpecValue.find_by(id: value_id)
      end
    end

    def length
      @length ||= dimension[:length]
    end

    def width
      @width ||= dimension[:width]
    end

    def height
      @height ||= dimension[:height]
    end

    def colors
      @colors ||= begin
        key     = SpecKey.find_by(id: @calculator.properties['print_color_a'])
        color_a = self._spec[key.id.to_s].try(:to_i)

        key     = SpecKey.find_by(id: @calculator.properties['print_color_b'])
        color_b = self._spec[key.id.to_s].try(:to_i) || 0

        [ color_a, color_b ]
      end
    end

    def color
      colors.max
    end

    def material
      @material ||= begin
        breakdown  = breakdowns.find {|b| b.code.downcase == 'material' }
        value_id   = self._spec[breakdown.relation.id.to_s]
        spec_value = SpecValue.find_by(id: value_id)
        spec_value.component
      end
    end

    def corrugated_type
      @corrugated_type ||= material&.properties['corrugated_type']&.to_s || 'single'
    end

    def fluting
      FLUTING[corrugated_type]
    end

    def additional
      ADDITIONAL[corrugated_type]
    end
  end

end
