module Prism
  class Calculator::FoldingFormula < Calculator::PostPressFormula
    COMPONENT_CODE = 'FOLDING'

    def folding_count
      @folding_count ||= begin
        spec_key = SpecKey.find_by(code: :folding)
        @product._spec[spec_key.id.to_s].try(:to_i)
      end
    end

    def price
      @price ||= [ratecard.price_minimum, @product.quantity * folding_count * tier.price].max
    end

    def set_description
      product_price[:folding_description] = <<~DESC
        Min Price: <b>#{ idr ratecard.price_minimum }</b>
        Jml Produk: <b>#{ number @product.quantity }</b>
        Jml Lipatan: <b>#{ number folding_count }</b>
        Biaya/lipat: <b>#{ idr tier.price }</b>

        <br />Perhitungan:
        Nilai MAX antara <b>Min Price</b> dengan <b>Jumlah Produk * (Jumlah Lipatan * Biaya/lipat)</b>
        <b>MAX(#{ idr ratecard.price_minimum }, #{ number @product.quantity } * (#{ number folding_count } * #{ idr tier.price }))</b>
      DESC
    end

    def calculate
      is_none = @product.spec[:folding]&.to_s&.upcase&.strip == 'NONE'
      if @product.spec[:folding].blank? || ratecard.blank? || is_none
        return 0
      end

      if @product.spec[:folding].present? && (component.blank? || ratecard.blank? || ratecard.partner_component.deactive?)
        @error = "[#{@product.printing_type}] Harga Lipat belum diisi."
        @product.prices.reject! { |p| p[:partner] == @partner && p[:machine] == @machine && p[:paper] == @paper }
        return -1
      end

      set_description
      product_price[:hours]         = 0 if product_price[:hours].blank?
      product_price[:hours]        += tier.production_time || 0
      product_price[:folding_price] = price
    end
  end

end
