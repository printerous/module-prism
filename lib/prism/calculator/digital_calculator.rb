# frozen_string_literal: true

module Prism
  class Calculator::DigitalCalculator
    BLEED = 2 # millimeter

    attr_reader   :params, :product_type_id, :quantity, :breakdowns, :printing_type
    attr_accessor :prices, :errors, :total

    # params
    # - product_type_id
    # - quantity
    # - [partner_id]
    # - printing_type
    # - spec: { spec_key: value|spec_value.id }
    # - size: { width: value, length: value } --> CUSTOM SIZE in mm

    def initialize(params)
      @paper_code      = 'a3320x450'
      @params          = params
      @product_type_id = params[:product_type_id]
      @quantity        = params[:quantity].to_f
      @partners        = Partner.where(id: [params[:partner_id]].flatten)

      @printing_type   = params[:printing_type] || 'digital'
      @calculator      = Prism::ProductCalculator.find_by(code: @printing_type)
      @breakdowns      = @calculator.product_calculator_breakdowns.order(position: :asc)
      @prices          = []
      @errors          = []
    end

    def calculate
      if @quantity.zero?
        @errors << "[#{printing_type}] Jumlah hasil jadi (Quantity) tidak boleh kosong. Mohon isi terlebih dahulu data yang dibutuhkan"
        Rails.logger.info @errors.to_s
        return @prices
      end

      if material.blank?
        @errors << "[#{printing_type}] Material tidak ditemukan"
        Rails.logger.info @errors.to_s
        return @prices
      end

      @partners.each do |partner|
        Rails.logger.info '*' * 100
        Rails.logger.info "== PARTNER #{partner.name} =="

        machines = partner.active_printing_machines.send(@printing_type.pluralize).order("properties -> 'position' ASC").uniq
        if machines.blank?
          @errors << "[#{printing_type}] Tidak ada Mesin yang aktif"
          Rails.logger.info @errors.to_s
          next
        end

        machines.each do |machine|
          paper = Prism::PrintingPaper.find_by(code: @paper_code)

          # OVERRIDE PAPER AREA
          cutting = spec[:cutting]
          if cutting.present? && cutting&.to_s&.upcase&.strip != 'NONE'
            paper.width  = 310 # sebelum dikurangi gripper 10mm
            paper.length = 410 # sebelum dikurangi gripper 10mm
          end

          impose_officer = impose_officer(paper)
          puts 'After Impose'
          impose_count = impose_officer.impose
          next if impose_count.zero?

          material_quantity = (quantity / impose_count).ceil

          @prices << result = {
            partner: partner,
            partner_id: partner.id,
            machine: machine,
            machine_id: machine.id,

            paper: paper,
            paper_id: 0,
            paper_length: paper.length,
            paper_width: paper.width,

            quantity: quantity,
            length: length,
            width: width,
            print_side: print_side,
            print_color: print_color,

            hours: 0,

            impose_officer: impose_officer,
            impose_quantity: impose_count,
            impose_orientation: impose_officer.orientation,
            material_quantity: material_quantity
          }.with_indifferent_access

          @total = 0
          @breakdowns.each do |breakdown|
            puts breakdown.module_formula

            formula_klass = breakdown.module_formula.constantize

            puts 'After formula_klass'
            puts formula_klass
            formula       = formula_klass.new(breakdown: breakdown, product: self, partner: partner, machine: machine, paper: paper)
            value         = formula.calculate

            Rails.logger.info "---------------------- #{breakdown.module_formula} : #{partner.name}------------------"
            Rails.logger.info "-------------------------- #{value} --------------------------"

            if value == -1
              begin
                @errors << formula.error
              rescue StandardError
                "[#{printing_type}] Gagal Menghitung. Mohon isi terlebih dahulu data yang dibutuhkan"
              end
              break
            end

            self.total += value
          end

          result[:price] = self.total / quantity.to_f
          result[:total] = self.total
        end
      end

      @prices.sort! { |a, b| [a[:total]] <=> [b[:total]] }
    end

    def impose_officer(paper)
      @impose_officer ||= Prism::Calculator::ImposeOfficer.new({
                                                          width: paper.width,
                                                          length: paper.length
                                                        }, dimension)
      end

    def impose_count(paper)
      impose_officer(paper).impose
    end

    def spec
      @spec ||= begin
        Hash[
          params[:spec].to_h.map do |k, v|
            spec_key = Prism::SpecKey.find(k)
            value    = Prism::SpecValue.find_by(id: v)&.name
            value    = v if spec_key.properties['is_direct']&.to_i == 1

            [spec_key.code, value]
          end
        ].with_indifferent_access
      end
    end

    def _spec
      @_spec ||= params[:spec].to_h.with_indifferent_access
    end

    def print_side
      @print_side ||= begin
        key        = Prism::SpecKey.find_by(id: @calculator.properties['print_side_id'])
        key_2      = Prism::SpecKey.find_by(code: 'printside')

        value_id   = _spec[key.id.to_s] || _spec[key_2.id.to_s]
        print_side = Prism::SpecValue.find_by(id: value_id)

        print_side&.properties.try(:[], 'side')&.to_i || 1
      end
    end

    def print_color
      @print_color ||= colors.max
    end

    def colors
      @colors ||= begin
        key     = Prism::SpecKey.find_by(id: @calculator.properties['print_color_a'])
        color_a = _spec[key.id.to_s].try(:to_i) || 0
        color_a = 4 if color_a > 4

        key     = Prism::SpecKey.find_by(id: @calculator.properties['print_color_b'])
        color_b = _spec[key.id.to_s].try(:to_i) || 0
        color_b = 4 if color_b > 4

        [color_a, color_b]
      end
    end

    def dimension
      @dimension ||= if params[:size].blank?
                       key = Prism::SpecKey.find_by(id: @calculator.properties['size_id'])
                       key_2 = Prism::SpecKey.find_by(code: 'ukuranprodukjadi')
                       value_id = _spec[key.id.to_s] || _spec[key_2.id.to_s]

                       size     = Prism::SpecValue.find_by(id: value_id) || Prism::SpecValue.new
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
      @print_length ||= length + 2 * Prism::Calculator::ImposeOfficer::BLEED
    end

    def width
      @width ||= dimension[:width]
    end

    def print_width
      @print_width ||= width + 2 * Prism::Calculator::ImposeOfficer::BLEED
    end

    def material
      @material ||= begin
        breakdown  = breakdowns.detect { |b| b.code.downcase == 'material' }
        value_id   = _spec[breakdown.relation.id.to_s]
        spec_value = Prism::SpecValue.find_by(id: value_id)
        spec_value&.component
      end
    end
  end
end
