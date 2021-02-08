module Prism
  class Calculator::BindingFormula < Calculator::PostPressFormula
    def price
      @price ||= [ratecard.price_minimum, @product.quantity * tier.price].max
    end

    def production_time
      product_price[:binding_hour] = begin
        speed = ratecard.properties['production_speed']&.to_f || 1
        [@product.quantity / speed, 1].max
      rescue
        0
      end
    end

    def set_description
      product_price[:binding_description] = <<~DESC
        Jumlah Product: <b>#{ number @product.quantity }</b>
        Biaya Binding: <b>#{ idr tier.price }</b>

        <br />Perhitungan:
        Jumlah Product * Biaya Binding
        <b>#{ number @product.quantity } * #{ idr tier.price }</b>
      DESC
    end

    def calculate
      is_none = ['NONE', 'NO'].include?(@product.spec[:binding]&.to_s&.upcase&.strip)
      if @product.spec[:binding].blank? || ratecard.blank? || is_none
        return 0
      end

      if @product.spec[:binding].present? && (component.blank? || ratecard.blank? || ratecard.partner_component.deactive?)
        @product.prices.reject! {|p| p[:partner] == @partner && p[:machine] == @machine && p[:paper] == @paper }
        return -1
      end

      set_description

      product_price[:hours]        += production_time
      product_price[:binding_price] = price
    end
  end

end
