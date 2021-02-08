module Prism
  class Calculator::GlueFormula < Calculator::PostPressFormula
    COMPONENT_CODE = 'GLUE'

    def price
      @price ||= [ratecard.price_minimum, @product.quantity * glue_length * tier.price].max
    end

    def set_description
      product_price['glue_description'] = <<~DESC
        Min Price: <b>#{ idr ratecard.price_minimum }</b>
        Jumlah Produk: <b>#{ number @product.quantity }</b>
        Panjang Lem: <b>#{ number glue_length }cm</b>
        Biaya/cm: <b>#{ idr tier.price }</b>

        <br/> Perhitungan:
        Nilai Max antara <b>Min Price</b> dengan <b>Jumlah Produk * (Panjang Lem(cm) * Biaya)</b>
        <b>MAX(#{ idr ratecard.price_minimum }, #{ number @product.quantity } * (#{ number glue_length } * #{ idr tier.price }))</b>
      DESC
    end

    def glue_length
      @glue_length ||= begin
        spec_key = SpecKey.find_by(code: :glue)
        @product._spec[spec_key.id.to_s].try(:to_f) / 10
      end
    end

    def production_time
      product_price["#{ @breakdown.code }_hour"] = begin
        tier.production_time
      end
    end

    def calculate
      if @product.spec[:glue].blank?
        return 0
      end

      if @product.spec[:glue].present? && (component.blank? || ratecard.blank?)
        @error = "[#{@product.printing_type}] Harga Lem belum diisi."
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
