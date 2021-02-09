module Prism
  class Calculator::Digital::FoldingFormula < Prism::Calculator::Digital::PostPressFormula
    def folding_count
      @folding_count ||= begin
        spec_key = SpecKey.find_by(code: :folding)
        value_id = @product._spec[spec_key.id.to_s]&.to_i

        if spec_key.is_direct? || (0..10).include?(value_id&.to_i)
          value_id
        else
          spec_value = SpecValue.find_by(id: value_id)
          spec_value.properties['folding'] || 0
        end
      end
    end

    def price
      @price ||= begin
        formula_price = product_price[:material_quantity] * material_folding_count * tier.price
        [ratecard.price_minimum, formula_price].max
      end
    end

    def material_folding_count
      @material_folding_count ||= begin
        officer = product_price[:impose_officer]

        impose_position = if officer.landscape?
          [officer.landscape_horizontal, officer.landscape_vertical].min
        else
          [officer.portrait_horizontal, officer.portrait_vertical].min
        end

        impose_position * folding_count
      end
    end

    def quantity_minimum
      tier.quantity_bottom || 0
    end

    def additional_quantity
      [product_price[:material_quantity] - quantity_minimum, 0].max
    end

    def production_time
      product_price[:folding_hour] = begin
        speed = ratecard.properties['production_speed']&.to_f
        @product.quantity / speed * folding_count
      rescue
        0
      end
    end

    def set_description
      product_price[:folding_description] = <<~DESC
        Jumlah Lipat Produk: <b>#{ number folding_count }</b>
        Jumlah Material: <b>#{ number product_price[:material_quantity] }</b>
        Biaya Lipat/Material: <b>#{ idr tier.price }</b>
        Biaya Minimum: <b>#{ idr ratecard.price_minimum }</b>

        <br />Perhitungan:
        MAX(Biaya Minimum, (Jumlah Material * Jumlah Lipat * Biaya Lipat)
        MAX(<b>#{ idr ratecard.price_minimum }</b>, (<b>#{ number product_price[:material_quantity] } * #{ number material_folding_count } * #{ idr tier.price })</b>)
      DESC
    end

    def calculate
      is_none = @product.spec[:folding]&.to_s&.upcase&.strip == 'NONE'
      if @product.spec[:folding].blank? || folding_count == 0 || is_none
        return 0
      end

      if @product.spec[:folding].present? && (component.blank? || ratecard.blank? || ratecard.partner_component.deactive?)
        @error = "[#{@product.printing_type}] Harga Lipat belum diisi."
        @product.prices.reject! { |p| p[:partner] == @partner && p[:machine] == @machine && p[:paper] == @paper }
        return -1
      end

      set_description

      product_price[:hours]         += production_time
      product_price[:folding_price] = price
    end
  end

end
