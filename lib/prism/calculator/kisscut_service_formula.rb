module Prism
  class Calculator::KisscutServiceFormula < Prism::Calculator::CuttingFormula
    def price_name
      "#{ @breakdown.code }_price"
    end

    def price
      @price ||= [ratecard.price_minimum, printing_quantity * tier.price].max
    end

    def production_time
      product_price["#{ @breakdown.code }_hour"] = tier.production_time
    end

    def set_description
      product_price["#{ @breakdown.code }_description"] = <<~DESC
        Min Price: <b>#{ idr ratecard.price_minimum }</b>
        Total Material: <b>#{ number printing_quantity }</b>
        Harga/lembar: <b>#{ idr tier.price }</b>

        <br />Perhitungan:
        Nilai MAX antara <b>Min Price</b> dengan <b>Total Material * Harga/lembar</b>
        <b>MAX(#{ idr ratecard.price_minimum }, #{ number printing_quantity } * #{ idr tier.price })</b>
      DESC
    end

    def calculate
      cutting = @product.params[:cutting]
      if cutting.blank? || cutting.keys.include?(@breakdown.code).blank?
        return 0
      end

      if cutting.present? && cutting.keys.include?(@breakdown.code).present? && (component.blank? || ratecard.blank?)
        @error = "[#{@product.printing_type}] Harga Jasa Kisscut belum diisi."
        @product.prices.reject! { |p| p[:partner] == @partner && p[:machine] == @machine && p[:paper] == @paper }
        return -1
      end

      set_description
      product_price[:hours]    += production_time
      product_price[price_name] = price
    end
  end

end
