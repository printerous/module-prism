# frozen_string_literal: true

module Prism
  class Calculator::LargeFormatCalculator
    BLEED = 2 # millimeter

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
      @params          = params
      @product_type_id = params[:product_type_id]
      @quantity        = params[:quantity].to_f
      @partners        = Partner.where(id: [params[:partner_id]].flatten)

      @printing_type   = params[:printing_type] || :large_format
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

      @partners.each do |partner|
        Rails.logger.info '*' * 100
        Rails.logger.info "== PARTNER #{partner.name} =="

        machines = partner.active_printing_machines.large_formats.order("properties -> 'position' ASC").uniq
        if machines.blank?
          @errors << "[#{printing_type}] Tidak ada Mesin yang aktif"
          Rails.logger.info @errors.to_s
          next
        end

        machines.each do |machine|
          machine_width     = machine.properties['max_paper_width']
          paper             = PrintingPaper.large_formats
                                           .where('width <= ?', machine_width)
                                           .where('width >= ?', print_width)
                                           .min_by(&:width)

          next if paper.blank?

          material_area     = (print_width * print_length / 1_000_000).round(2)
          @prices << result = {
            partner: partner,
            partner_id: partner.id,
            machine: machine,
            machine_id: machine.id,

            paper: paper,
            paper_id: paper.id,
            paper_length: print_length,
            paper_width: paper.width,

            quantity: quantity,
            length: length,
            width: width,
            print_side: 1,
            print_color: print_color,

            hours: 0,
            material_area: material_area
          }.with_indifferent_access

          total = 0
          # Material - Finishing
          @breakdowns.each do |breakdown|
            formula = breakdown.module_formula.constantize
            value   = formula.new(breakdown: breakdown, product: self, partner: partner, machine: machine, paper: paper).calculate
            Rails.logger.info "---------------------- #{breakdown.module_formula} : #{partner.name}------------------"
            Rails.logger.info "-------------------------- #{value} --------------------------"

            if value == -1
              begin
                @errors << formula.error
              rescue StandardError
                "[#{printing_type}] Gagal Menghitung <b>#{breakdown.name}</b>. Mohon isi terlebih dahulu data yang dibutuhkan"
              end
              break
            end

            total += value
          end

          @errors.flatten!
          result[:price] = total / quantity.to_f
          result[:total] = total
        end
      end

      @prices.sort! { |a, b| [a[:total]] <=> [b[:total]] }
    end

    def spec
      @spec ||= begin
        Hash[
          params[:spec].to_h.map do |k, v|
            [
              SpecKey.find(k).code,
              SpecKey.find(k).properties['is_direct'] == 1 ? v : SpecValue.find_by(id: v).try(:name)
            ]
          end
        ].with_indifferent_access
      end
    end

    def _spec
      @_spec ||= params[:spec].to_h.with_indifferent_access
    end

    def print_color
      @print_color ||= colors.max
    end

    def colors
      @colors ||= begin
        key     = SpecKey.find_by(id: @calculator.properties['print_color_a'])
        color_a = _spec[key.id.to_s].try(:to_i) || 4

        [color_a, 0]
      end
    end

    def dimension
      @dimension ||= if params[:size].blank?
                       key = SpecKey.find_by(id: @calculator.properties['size_id'])
                       key_2 = SpecKey.find_by(code: 'ukuranprodukjadi')
                       value_id = _spec[key.id.to_s] || _spec[key_2.id.to_s]

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

    def additional_length
      # return 2 * 50   if finishing&.code == 'na'
      # return 2 * 30   if finishing&.code == 'mataayam'
      # return 2 * 100  if finishing&.code == 'SLEEVE_VERTICAL'
      0
    end

    def additional_width
      # return 2 * 50   if finishing&.code == 'na'
      # return 2 * 30   if finishing&.code == 'mataayam'
      # return 2 * 100  if finishing&.code == 'SLEEVE_HORIZONTAL'
      0
    end

    def print_length
      @print_length ||= begin
        pl = length + additional_length

        if pl < 1000
          1000
        else
          pl
        end
      end
    end

    def width
      @width ||= dimension[:width]
    end

    def print_width
      @print_width ||= begin
        pw = width + additional_width

        if pw < 1000
          1000
        else
          pw
        end
      end
    end

    def material
      @material ||= begin
        breakdown  = breakdowns.find { |b| b.code.downcase == 'material' }
        value_id   = _spec[breakdown.relation.id.to_s]
        spec_value = SpecValue.find_by(id: value_id)
        spec_value.component
      end
    end

    def finishing
      @finishing ||= begin
        spec_key = SpecKey.find_by(code: :finishing)
        return unless value_id = _spec[spec_key.id.to_s]

        SpecValue.find_by(id: value_id)
      end
    end
  end
end
