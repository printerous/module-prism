module Prism
  class Calculator::PackingFormula < Calculator::PostPressFormula
    COMPONENT_CODE = 'PACKING'

    def ratecard
      @ratecard = PartnerRatecard.joins(:component).find_by(partner_id: @partner.id, version: 'ALL', 'components.id': component.id)
    end

    # get product quantity
    def product_qty
      @product_qty ||= product_price[:quantity]
    end

    # get user input for product number / pack
    def package_qty
      @package_qty ||= @product.params[:packing]['packing'].to_i
    end

    # count number of pack
    def product_pack_qty
      @product_pack_qty ||= (product_qty.to_f / package_qty).ceil.to_i
    end

    def price
      @price ||= tier.value * product_pack_qty
    end

    def production_time
      0
    end

    def set_description
      product_price["#{ @breakdown.code }_description"] = <<~DESC
        Packing Cost: <b>#{ idr tier.value }</b>
        Produk Qty: <b>#{ product_qty }</b>
        Produk/Pack: <b>#{ package_qty }</b>
        ---
        Jumlah Package: <b>#{ number product_pack_qty }</b>

        <br />Perhitungan:
        (<b>Jumlah Produk Jadi</b> / <b>Jumlah Produk/Pack</b>) * <b>Harga Packing</b>
        (<b>#{ product_qty }</b> / <b>#{ package_qty }</b>) * <b>#{ idr tier.value }</b>
      DESC
    end

    def calculate
      if @product.spec[:packing].blank?
        return 0
      end

      if @product.spec[:packing].present? && (component.blank? || ratecard.blank?)
        @error = "[#{@product.printing_type}] Harga Biaya Packing belum diisi."
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
