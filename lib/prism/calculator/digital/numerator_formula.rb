module Prism
  class Calculator::Digital::NumeratorFormula < Prism::Calculator::Digital::PostPressFormula
    def price
      @price ||= @product.total * (tier.price / 100.to_f)
    end

    def production_time
      0
    end

    def set_description
      product_price[:numerator_description] = <<~DESC
        Total Price: <b>#{ idr @product.total }</b>
        Biaya Numerator: <b>#{ number_decimal tier.price }%</b>

        <br />Perhitungan:
        Total Price * Biaya Numerator
        <b>#{ idr @product.total } * #{ number_decimal tier.price }%</b>
      DESC
    end

    def calculate
      is_none = ['NONE', 'NO'].include?(@product.spec[:numerator]&.to_s&.upcase&.strip)
      if @product.spec[:numerator].blank? || is_none
        return 0
      end

      if @product.spec[:numerator].present? && (component.blank? || ratecard.blank? || ratecard.partner_component.deactive?)
        @error = "[#{@product.printing_type}] Harga Numerator belum diisi."
        @product.prices.reject! { |p| p[:partner] == @partner && p[:machine] == @machine && p[:paper] == @paper }
        return -1
      end

      set_description

      product_price[:hours]          += production_time
      product_price[:numerator_price] = price
    end
  end

end
