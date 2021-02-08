module Prism
  class Calculator::SpotUVFormula < Prism::Calculator::PostPressFormula
    INSHEET_CODE = 'INSHEET_SPOT_UV'

    def spec_value
       @spec_value ||= begin
        spec_key   = SpecKey.find_by(code: :spot_uv)
        value_id   = @product._spec[spec_key.id.to_s]
        spec_value = SpecValue.find_by(id: value_id)
      end
    end

    def side
      properties = spec_value.try(:properties)
      @side ||= properties['side'] rescue 0
    end

    def price
      @price ||= begin
        value = @paper.width * @paper.length / 100 * finishing_quantity * tier.price * side
        [ratecard.price_minimum, value].max
      end
    end

    def production_time
      product_price["#{ @breakdown.code }_hour"] = begin
        hour = tier.production_time

        hour
      end
    end

    def set_description
      product_price["#{ @breakdown.code }_description"] = <<~DESC
        Min Price: <b>#{ idr ratecard.price_minimum }</b>
        Paper Width: <b>#{ @paper.width / 10 }cm</b>
        Paper Length: <b>#{ @paper.length / 10 }cm</b>
        Total Material: <b>#{ number finishing_quantity }</b>
        ---
        Spot UV : <b>#{spec_value.name}</b>
        Harga Spot UV #{side}sisi/cm2: <b>#{ idr tier.price }</b>
        <br />Perhitungan:
        Nilai MAX antara <b>Min Price</b> dengan <b>Luas Kertas (cm2) * Total Material * Harga Spot UV/cm2 * Jumlah Sisi </b>
        <b>MAX</b>(#{ idr ratecard.price_minimum }, <b>( (#{ @paper.width / 10.to_f } * #{ @paper.length / 10.to_f}) * #{ number printing_quantity } * #{ idr tier.price } * #{side})</b>
      DESC
    end

    def calculate
      if @product.spec[:spot_uv].blank?
        return 0
      end

      if @product.spec[:spot_uv].present? && (component.blank? || ratecard.blank?)
        @error = "[#{@product.printing_type}] Harga Spot UV belum diisi."
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
