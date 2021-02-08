module Prism
  class Calculator::PondServiceFormula < Calculator::CuttingFormula
    AVAILABLE_SERVICE = ['diecut_service', 'rel_service', 'perforation_service', 'emboss', 'deboss']
    INSHEET_CODE = 'INSHEET_POND_SERVICE'

    def services
      (@product.params[:cutting].try(:keys) || []) + (@product.params[:plat_emboss].try(:keys) || [])
    end

    def price_name
      "#{ @breakdown.code }_price"
    end

    def price
      @price ||= [ratecard.price_minimum, finishing_quantity * tier.price].max
    end

    def production_time
      product_price["#{ @breakdown.code }_hour"] = tier.production_time
    end

    def set_description
      product_price["#{ @breakdown.code }_description"] = <<~DESC
        Min Price: <b>#{ idr ratecard.price_minimum }</b>
        Total Material: <b>#{ number finishing_quantity }</b>
        Harga/lembar: <b>#{ idr tier.price }</b>

        <br />Perhitungan:
        Nilai MAX antara <b>Min Price</b> dengan <b>Total Material * Harga/lembar</b>
        <b>MAX(#{ idr ratecard.price_minimum }, #{ number finishing_quantity } * #{ idr tier.price })</b>
      DESC
    end

    def calculate
      if services.blank? || (services & self.class::AVAILABLE_SERVICE).blank?
        return 0
      end

      if services.present? && (services & self.class::AVAILABLE_SERVICE).present? && (component.blank? || ratecard.blank?)
        @error = "[#{@product.printing_type}] Harga Jasa (Diecut, Kisscut, Perforasi, Rel, Emboss, Deboss) belum diisi."
        @product.prices.reject! { |p| p[:partner] == @partner && p[:machine] == @machine && p[:paper] == @paper }
        return -1
      end

      set_description
      product_price[:hours]           += production_time
      product_price[price_name] = price
    end
  end

end
