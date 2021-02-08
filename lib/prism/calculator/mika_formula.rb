module Prism
  class Calculator::MikaFormula < Calculator::PostPressFormula
    def price
      @price ||= @product.quantity * tier.price
    end

    def production_time
      product_price[:mika_hour] = begin
        speed = ratecard.properties['production_speed']&.to_f || 1
        [@product.quantity / speed, 1].max
      rescue
        0
      end
    end

    def set_description
      product_price[:mika_description] = <<~DESC
        Jumlah Product: <b>#{ number @product.quantity }</b>
        Biaya Mika: <b>#{ idr tier.price }</b>

        <br />Perhitungan:
        Jumlah Product * Biaya Mika
        <b>#{ number @product.quantity } * #{ idr tier.price }</b>
      DESC
    end

    def calculate
      is_none = ['NONE', 'NO'].include?(@product.spec[:mika]&.to_s&.upcase&.strip)
      if @product.spec[:mika].blank? || ratecard.blank? || is_none
        return 0
      end

      if @product.spec[:mika].present? && (component.blank? || ratecard.blank? || ratecard.partner_component.deactive?)
        @product.prices.reject! {|p| p[:partner] == @partner && p[:machine] == @machine && p[:paper] == @paper }
        return -1
      end

      set_description

      product_price[:hours]     += production_time
      product_price[:mika_price] = price
    end
  end
end
