module Prism
  class Calculator::Website::SpecIdMapper
    attr_reader :spec_id, :calc_spec_id

    def initialize(spec_id)
      @spec_id      = spec_id # Keys and Values are all in string
      @calc_spec_id = @spec_id

      @size_id      = Prism::SpecKey.find_by(code: 'size').id.to_s
      @printside_id = Prism::SpecKey.find_by(code: 'printside').id.to_s
      @printside    = Prism::SpecValue.find_by(id: spec_id[@printside_id])
      @side_prop    = @printside&.properties || {}
      @side         = @side_prop['side'] || 1
    end

    def normalize
      # Handle NONE
      @spec_id.merge!(spec_id) do |key_id, value_id|
        if Prism::SpecValue.find_by(id: value_id)&.code&.upcase != 'NA'
          value_id
        end
      end

      normalize_print_color
      normalize_folding
      normalize_size
      normalize_lamination
      normalize_finishing
      normalize_glue

      calc_spec_id
    end

    def dimension
      sv = Prism::SpecValue.find_by(id: spec_id[@size_id])
      width  = sv.properties['width_in_mm'] || 0
      length = sv.properties['length_in_mm'] || 0

      {
        width: width,
        length: length
      }.with_indifferent_access
    end

    def portrait?
      dimension[:width] > dimension[:length]
    end

    def landscape?
      dimension[:width] < dimension[:length]
    end

    private

    def normalize_print_color
      color_a_id   = Prism::SpecKey.find_by(code: 'print_color_a').id.to_s
      color_b_id   = Prism::SpecKey.find_by(code: 'print_color_b').id.to_s

      no_printside  = !spec_id.keys.include?(@printside_id)
      color_defined = ([color_a_id, color_b_id] - spec_id.keys).empty?
      color_a       = spec_id[color_a_id]&.to_i || 0
      color_b       = spec_id[color_b_id]&.to_i || 0

      # Return IF color is defined but not greater than 4
      return if no_printside || (color_defined && [color_a, color_b].all? { |x| x <= 4 })

      calc_spec_id.merge!({ color_a_id => '4', color_b_id => @side_prop['print_color_b'] })
    end

    def normalize_folding
      spec_key   = Prism::SpecKey.find_by(code: 'folding')
      folding_id = spec_key.id.to_s
      value_id   = spec_id[folding_id]
      return if value_id.blank?

      if spec_key.is_direct? && !(0..10).include?(value_id&.to_i)
        props    = Prism::SpecValue.find_by(id: value_id)&.properties || {}
        value_id = props['folding']&.to_s || '0'
      end

      calc_spec_id.merge!({ folding_id => value_id })
    end

    def normalize_size
      closed_size_id = Prism::SpecKey.find_by(code: 'ukuranprodukjadi').id.to_s
      return if spec_id[@size_id].present? || spec_id[closed_size_id].blank?

      # Ukuran Produk Jadi x Folding
      folding_id = Prism::SpecKey.find_by(code: 'folding').id.to_s
      if spec_id[folding_id].present?
      else
      end
    end

    def normalize_lamination
      lamination_id   = Prism::SpecKey.find_by(code: 'lamination_ab')&.id&.to_s
      return if spec_id[lamination_id].blank?

      lamination_a_id = Prism::SpecKey.find_by(code: 'lamination')&.id&.to_s
      lamination_b_id = Prism::SpecKey.find_by(code: 'lamination_b')&.id&.to_s
      spec_value      = Prism::SpecValue.find_by(id: spec_id[lamination_id]) || Prism::SpecValue.find_by(id: spec_id[lamination_a_id])
      spec_value_id   = spec_value&.id&.to_s

      lamination_spec = { lamination_a_id => spec_value_id }

      if @side == 2
        lamination_spec[lamination_b_id] = spec_value_id
      end

      calc_spec_id.merge!(lamination_spec)
    end

    def normalize_finishing
      finishing = Prism::SpecKey.find_by(code: 'finishing')
      return if spec_id[finishing.id.to_s].blank?

      spec_value = Prism::SpecValue.find_by(id: spec_id[finishing.id.to_s])
      normalize_perforation(spec_value)
      normalize_numerator(spec_value)
      normalize_mika(spec_value)
      normalize_double_tape(spec_value)
    end

    def normalize_glue
      glue_key = Prism::SpecKey.find_by(code: :glue)
      glue_id  = glue_key.id.to_s
      return if spec_id[glue_id].blank?

      spec_value = Prism::SpecValue.find_by(id: spec_id[glue_id])
      return if spec_value.blank? || spec_value&.code != 'yes'

      length = dimension[:width]
      if landscape?
        length = dimension[:length]
      end

      calc_spec_id.merge!({ glue_id => length&.to_s })
    end

    def normalize_perforation(spec_value)
      return unless ['perforation', 'numerator_perforation'].include?(spec_value&.code)

      perforation_id = Prism::SpecKey.find_by(code: 'perforation').id.to_s
      yes_id         = Prism::SpecValue.find_by(code: 'yes').id.to_s
      calc_spec_id.merge!({ perforation_id => yes_id })
    end

    def normalize_numerator(spec_value)
      return unless ['numerator', 'numerator_perforation'].include?(spec_value&.code)

      numerator_id = Prism::SpecKey.find_by(code: 'numerator').id.to_s
      yes_id       = Prism::SpecValue.find_by(code: 'yes').id.to_s
      calc_spec_id.merge!({ numerator_id => yes_id })
    end

    def normalize_mika(spec_value)
      return unless ['mika'].include?(spec_value&.code)

      mika_id = Prism::SpecKey.find_by(code: 'mika').id.to_s
      yes_id  = Prism::SpecValue.find_by(code: 'yes').id.to_s
      calc_spec_id.merge!({ mika_id => yes_id })
    end

    def normalize_double_tape(spec_value)
      return unless ['double_tape'].include?(spec_value&.code)

      mika_id = Prism::SpecKey.find_by(code: 'double_tape').id.to_s
      yes_id  = Prism::SpecValue.find_by(code: 'yes').id.to_s
      calc_spec_id.merge!({ mika_id => yes_id })
    end
  end

end
