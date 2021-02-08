module Prism
  class Calculator::EmbossDebossFormula < Calculator::PostPressFormula
    COMPONENT_CODE = 'PLAT_EMBOSS_DEBOSS'

    def area
      @product.params[:plat_emboss_deboss].values.sum(&:to_i)
    end

    def price
      [ratecard.price_minimum, area * tier.price * product_price[:printing_mode].impose_count].max
    end

    def price_name
      "#{ @breakdown.code }_price"
    end

    def set_description
      product_price["#{ @breakdown.code }_description"] = <<~DESC
        Min Price: <b>#{ idr ratecard.price_minimum }</b>
        Jml Mata: <b>#{ product_price[:printing_mode].impose_count }</b>
        #{
          if @product.params[:plat_emboss_deboss][:emboss]
            " ----
            <b>Emboss</b>
            Luas area: <b>#{ number_decimal @product.params[:plat_emboss_deboss][:emboss] }cm2</b>
            Harga/cm2: <b>#{ idr tier.price }</b>
            "
          end
        }
        #{
          if @product.params[:plat_emboss_deboss][:deboss]
            " ----
            <b>Deboss</b>
            Luas area: <b>#{ number_decimal @product.params[:plat_emboss_deboss][:deboss] }cm2</b>
            Harga/cm2: <b>#{ idr tier.price }</b>
            "
          end
        }
        ----
        Total luas area: <b>#{ number_decimal area }cm2</b>

        <br />Perhitungan:
        Nilai MAX antara <b>Min Price</b> dengan <b>Total Luas area * Harga/cm2 * Jumlah Mata</b>
        <b>MAX(#{ idr ratecard.price_minimum } <b>&</b> #{ number_decimal area }cm2 * #{ idr tier.price } * #{ product_price[:printing_mode].impose_count })</b>
      DESC
    end

    def calculate
      if @product.params[:plat_emboss_deboss].blank?
        return 0
      end

      if @product.params[:plat_emboss_deboss].present? && (component.blank? || ratecard.blank?)
        @error = "[#{@product.printing_type}] Harga Biaya Plat Deboss/Emboss belum diisi."
        @product.prices.reject! { |p| p[:partner] == @partner && p[:machine] == @machine && p[:paper] == @paper }
        return -1
      end

      set_description
      product_price[price_name] = price
    end
  end
end
