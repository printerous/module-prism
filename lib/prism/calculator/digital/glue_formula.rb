module Prism
  class Calculator::Digital::GlueFormula < Prism::Calculator::Digital::PostPressFormula
    COMPONENT_CODE = 'GLUE'

    def component
      @component ||= Component.find_by(code: self.class::COMPONENT_CODE)
    end

    def price
      @price ||= @product.quantity * tier.price
    end

    def production_time
      product_price[:glue_hour] = begin
        speed = ratecard.properties['production_speed']&.to_f
        @product.quantity / speed * 1
      rescue
        0
      end
    end

    def set_description
      product_price[:glue_description] = <<~DESC
        Jumlah Produk: <b>#{ number @product.quantity }</b>
        Biaya Lem: <b>#{ idr tier.price }/produk</b>

        <br />Perhitungan:
        Quantity * Biaya Lem
        <b>#{ number @product.quantity } * #{ idr tier.price }</b>
      DESC
    end

    def calculate
      is_none = @product.spec[:glue]&.to_s&.upcase&.strip == 'NONE'
      if @product.spec[:glue].blank? || @product.spec[:glue].try(:to_i) == 0 || is_none
        return 0
      end

      if @product.spec[:glue].present? && (component.blank? || ratecard.blank? || ratecard.partner_component.deactive?)
        @error = "[#{@product.printing_type}] Harga Lem belum diisi."
        @product.prices.reject! { |p| p[:partner] == @partner && p[:machine] == @machine && p[:paper] == @paper }
        return -1
      end

      set_description

      product_price[:hours]     += production_time
      product_price[:glue_price] = price
    end
  end

end
