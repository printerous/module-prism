require File.dirname(__FILE__) + '/post_press_formula.rb'

module Prism
  class Calculator::Digital::CuttingFormula < Prism::Calculator::Digital::PostPressFormula
    COMPONENT_CODE = 'cutting'

    def component
      @component ||= begin
        spec_key   = @breakdown.relation
        value_id   = @product._spec[spec_key.id.to_s]
        spec_value = SpecValue.find_by(id: value_id)
        spec_value.component_for('digital')
      end
    end

    def printing_quantity
      product_price[:material_quantity]
    end

    def price_name
      "#{ @breakdown.code }_price"
    end

    def price
      @price ||= printing_quantity * tier.price
    end

    def production_time
      product_price["#{ @breakdown.code }_hour"] = tier.production_time || 0
    end

    def set_description
      product_price["#{ @breakdown.code }_description"] = <<~DESC
        Jenis Cutting: <b>#{ @product.spec[:cutting] }</b>
        Total Material: <b>#{ number printing_quantity }</b>
        Harga/lembar: <b>#{ idr tier.price }</b>

        <br />Perhitungan:
        <b>Total Material * Harga/lembar</b>
        <b>#{ number printing_quantity } * #{ idr tier.price }</b>
      DESC
    end

    def calculate
      cutting = @product.spec[:cutting]
      is_none = @product.spec[:cutting]&.to_s&.upcase&.strip == 'NONE'
      if cutting.blank? || is_none
        return 0
      end

      if cutting.present? && (component.blank? || ratecard.blank?)
        @error = "[#{@product.printing_type}] Harga Cutting belum diisi."
        @product.prices.reject! { |p| p[:partner] == @partner && p[:machine] == @machine && p[:paper] == @paper }
        return -1
      end

      set_description
      product_price[:hours]    += production_time
      product_price[price_name] = price
    end
  end

end
