module Prism
  class Calculator::OffsetCalculator
    BLEED = 3 # millimeter

    attr_reader   :params, :product_type_id, :quantity, :breakdowns, :printing_type
    attr_accessor :prices, :errors

    # params
    # - product_type_id
    # - quantity
    # - [partner_id]
    # - printing_type
    # - spec: { spec_key: value|spec_value.id }
    # - size: { width: value, length: value } --> CUSTOM SIZE in mm

    def initialize(params)
      @params          = params.with_indifferent_access
      @product_type_id = params[:product_type_id]
      @quantity        = params[:quantity].to_f
      @partners        = Partner.where(id: [ params[:partner_id] ].flatten)

      @printing_type   = params[:printing_type].try(:downcase) || :offset
      @calculator      = Prism::ProductCalculator.find_by(code: printing_type)
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

        machines = partner.active_printing_machines.offsets.order("properties -> 'position' ASC").uniq
        if machines.blank?
          @errors << "[#{printing_type}] Tidak ada Mesin yang aktif"
          Rails.logger.info "#{@errors}"
          next
        end

        if papers(partner).blank?
          @errors << "[#{printing_type}] Tidak ada Kertas Material yang aktif"
          Rails.logger.info "#{@errors}"
          next
        end

        machines.each do |machine|
          fit_to_machines = papers(partner).select {|p|
            p.width.try(:to_f) >= machine.properties['min_paper_width'].try(:to_f) && p.width.try(:to_f) <= machine.properties['max_paper_width'].try(:to_f) &&
            p.length.try(:to_f) >= machine.properties['min_paper_length'].try(:to_f) && p.length.try(:to_f) <= machine.properties['max_paper_length'].try(:to_f)
          }

          fit_to_machines.each do |paper|
            printing_mode = Prism::Calculator::PrintingModeOfficer.new(
              gripper:      machine.properties['gripper'].to_f,
              paper_length: paper.length,
              paper_width:  paper.width,
              quantity:     quantity,
              width:        width,
              length:       length,
              print_side:   print_side,
              colors:       colors,
              lamination:   spec[:lamination],
              lamination_b: spec[:lamination_b]
            )

            next if printing_mode.impose_count.zero?

            material_quantity = (quantity / printing_mode.impose_count).ceil
            waste_quantity = Prism::Calculator::InsheetFormula.new(
              partner:            partner,
              print_side:         print_side,
              print_color:        print_color,
              printing_mode:      printing_mode.mode.to_s,
              material_quantity:  material_quantity,
              product_spec:       _spec
            ).calculate

            @prices << result = {
              partner:                 partner,
              partner_id:              partner.id,
              machine:                 machine,
              machine_id:              machine.id,

              paper:                   paper,
              paper_id:                paper.id,
              paper_length:            paper.length,
              paper_width:             printing_mode.paper_width,

              quantity:                quantity,
              length:                  length,
              width:                   width,
              print_side:              print_side,
              print_color:             print_color,

              hours:                   0,
              printing_mode:           printing_mode,

              impose_quantity:         printing_mode.impose_count,
              material_quantity:       material_quantity,
              waste_quantity:          waste_quantity,
              total_material_quantity: material_quantity + waste_quantity,
              plate_design:            printing_mode.plate_design
            }.with_indifferent_access

            total = 0
            @breakdowns.each do |breakdown|
              formula = breakdown.module_formula.constantize
              value   = formula.new(breakdown: breakdown, product: self, partner: partner, machine: machine, paper: paper).calculate
              Rails.logger.info "---------------------- #{breakdown.module_formula} : #{ partner.name }------------------"
              Rails.logger.info "-------------------------- #{value} --------------------------"

              if value == -1
                if machine_breakdowns.include?(breakdown.code)
                  @errors << "[#{printing_type}] Gagal Menghitung <b>#{breakdown.name}</b> untuk mesin <b>#{machine.name}</b>. Mohon isi terlebih dahulu data yang dibutuhkan"
                else
                  @errors << formula.error rescue "[#{printing_type}] Gagal Menghitung <b>#{breakdown.name}</b>. Mohon isi terlebih dahulu data yang dibutuhkan"
                end

                break
              end

              total += value
            end

            prodution_time_formula = Prism::Calculator::ProductionTimeFormula.new(
              product: self,
              partner: partner,
              machine: machine,
              paper: paper,
              total_material_quantity: material_quantity + waste_quantity
            )

            production_time = prodution_time_formula.calculate

            if production_time == -1
              @errors += prodution_time_formula.errors
              break
            end

            @errors.flatten!
            result[:hours] = production_time
            result[:price] = total / quantity.to_f
            result[:total] = total
          end
        end
      end

      @prices.sort! { |a, b| [a[:total]] <=> [b[:total]] }
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

        print_side&.properties.try(:[], 'side')&.to_i || 1
      end
    end

    def print_color
      @print_color ||= colors.max
    end

    def colors
      @colors ||= begin
        key     = SpecKey.find_by(id: @calculator.properties['print_color_a'])
        color_a = self._spec[key.id.to_s].try(:to_i)
        color_a = 4 if color_a > 4

        key     = SpecKey.find_by(id: @calculator.properties['print_color_b'])
        color_b = self._spec[key.id.to_s].try(:to_i) || 0
        color_b = 4 if color_b > 4

        [color_a, color_b]
      end
    end

    def dimension
      @dimension ||= if params[:size].blank?
        key      = SpecKey.find_by(id: @calculator.properties['size_id'])
        key_2    = SpecKey.find_by(code: 'ukuranprodukjadi')
        value_id = self._spec[key.id.to_s] || self._spec[key_2.id.to_s]

        size     = SpecValue.find_by(id: value_id) || SpecValue.new
        width    = size&.properties['width_in_mm']&.to_f || 0
        length   = size&.properties['length_in_mm']&.to_f || 0

        {
          width: width,
          length: length
        }
      else
        {
          width: params[:size][:width]&.to_f,
          length: params[:size][:length]&.to_f
        }
      end
    end

    def length
      @length ||= dimension[:length]
    end

    def print_length
      @print_length ||= length + 2 * Calculator::PrintingModeOfficer::BLEED
    end

    def width
      @width ||= dimension[:width]
    end

    def print_width
      @print_width ||= width + 2 * Calculator::PrintingModeOfficer::BLEED
    end

    def material
      @material ||= begin
        breakdown  = breakdowns.find {|b| b.code.downcase == 'material' }
        value_id   = self._spec[breakdown.relation.id.to_s]
        spec_value = SpecValue.find_by(id: value_id)
        spec_value.component
      end
    end

    def papers(partner)
      @papers ||= begin
        active_ratecard = material.partner_ratecards.where(partner: partner).active_ratecard.map(&:version).uniq
        base_papers     = material.printing_papers.where(code: active_ratecard) rescue []
        child_papers    = material.printing_papers.where(paper_base_id: base_papers.map(&:id)) rescue []

        base_papers + child_papers
      end
    end

    def machine_breakdowns
      @machine_breakdowns = ['setting', 'plate_cost', 'printing_cost']
    end

    def paper_bbs?
      if printing_mode

      end
    end
  end
end
