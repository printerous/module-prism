module Prism
  class Calculator::CuttingFormula < Prism::Calculator::PostPressFormula
    COMPONENT_CODE = 'CUTTING_SISIR'

    def price_name
      'cutting_sisir'
    end

    def price
      @price ||= [ratecard.price_minimum, printing_weight * tier.price].max
    end

    def production_time
      product_price["#{ @breakdown.code }_hour".to_sym] = tier.production_time || 0
    end

    def set_description
      product_price["#{ @breakdown.code }_description"] = <<~DESC
        Min Price: <b>#{ idr ratecard.price_minimum }</b>
        Total Berat Material: <b>#{ number_decimal printing_weight }kg</b>
        Harga/kg: <b>#{ idr tier.price }</b>

        <br />Perhitungan:
        Nilai MAX antara <b>Min Price</b> dengan <b>Total Berat Material * Harga/kg</b>
        <b>MAX(#{ idr ratecard.price_minimum }, #{ number_decimal printing_weight }kg * #{ idr tier.price })</b>
      DESC
    end

    def calculate
      if @product.params[:cutting].present?
        return 0
      end

      if @product.params[:cutting].blank? && (component.blank? || ratecard.blank? || ratecard.partner_component.deactive?)
        @error = "[#{@product.printing_type}] Harga Cutting Sisir belum diisi."
        @product.prices.reject! { |p| p[:partner] == @partner && p[:machine] == @machine && p[:paper] == @paper }
        return -1
      end

      set_description
      product_price[:hours] += production_time
      product_price["#{ @breakdown.code }_price"] = price

      return price
    end
  end
end
