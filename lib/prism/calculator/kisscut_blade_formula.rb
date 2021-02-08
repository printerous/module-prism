module Prism
  class Calculator::KisscutBladeFormula < Calculator::CuttingFormula
    COMPONENT_CODE = 'kisscut'

    def price_name
      "#{ @breakdown.code }_price"
    end

    def blade_length
      @blade_length ||= @product.params[:cutting]["#{ self.class::COMPONENT_CODE }"].try(:to_f) / 10
    end

    def price
      @price ||= [ratecard.price_minimum, blade_length * tier.price * product_price[:printing_mode].impose_count].max
    end

    def production_time
      product_price["#{ @breakdown.code }_hour"] = tier.production_time rescue 0
    end

    def set_description
      product_price["#{ @breakdown.code }_description"] = <<~DESC
        Min Price: <b>#{ idr ratecard.price_minimum }</b>
        Keliling Pisau: <b>#{ number_decimal blade_length }cm</b>
        Harga/cm: <b>#{ idr tier.price }</b>
        Jml Muka: <b>#{ product_price[:printing_mode].impose_count }</b>

        <br />Perhitungan:
        Nilai MAX antara <b>Min Price</b> dengan <b>Panjang(atau Keliling) Pisau * Harga/cm * Jumlah Muka</b>
        <b>MAX(#{ idr ratecard.price_minimum }, #{ number_decimal blade_length }cm * #{ idr tier.price } * #{ product_price[:printing_mode].impose_count })</b>
      DESC
    end

    def calculate
      cutting = @product.params[:cutting]

      if cutting.blank? || cutting.keys.include?(self.class::COMPONENT_CODE).blank?
        return 0
      end

      if cutting.present? && cutting.keys.include?(self.class::COMPONENT_CODE).present? && (component.blank? || ratecard.blank? || blade_length.zero?)
        @error = "[#{@product.printing_type}] Harga Pisau Kisscut belum diisi."
        @product.prices.reject! { |p| p[:partner] == @partner && p[:machine] == @machine && p[:paper] == @paper }
        return -1
      end

      set_description
      product_price[:hours]    += production_time
      product_price[price_name] = price
    end
  end

end
