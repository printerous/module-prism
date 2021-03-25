module Prism
  class Calculator::LargeFormat::FinishingFormula
    include ActionView::Helpers::NumberHelper
    include Prism::ApplicationHelper
    attr_reader :error

    def initialize(**params)
      @breakdown = params[:breakdown]
      @product   = params[:product]
      @partner   = params[:partner]
      @machine   = params[:machine]
      @paper     = params[:paper]
      @error     = nil
    end

    def spec_value
      @spec_value ||= begin
        spec_key   = @breakdown.relation
        return unless value_id = @product._spec[spec_key.id.to_s]

        SpecValue.find_by(id: value_id)
      end
    end

    def mataayam?
      spec_value&.code == 'mataayam'
    end

    def talispanduk?
      spec_value&.code == 'talispanduk'
    end

    def taliumbulumbul?
      spec_value&.code == 'taliumbulumbul'
    end

    def component
      @component ||= spec_value&.component
    end

    def product_price
      @product_price ||= @product.prices.find {|p| p[:partner] == @partner && p[:machine] == @machine && p[:paper] == @paper }
    end

    def finishing_ratecard
      return if component.blank?

      Prism::PartnerRatecard.joins(:component).find_by(partner_id: @partner.id, version: 'LARGE_FORMAT', 'components.id': component&.id)
    end

    def finishing_tier
      finishing_ratecard.tiers.last
    end

    def less_than_1m2?
      product_price[:product_wide] < 1.0
    end

    def greater_than_1m2?
      !less_than_1m2?
    end

    def finishing_quantity
      product_price[:finishing_quantity] = begin
        if less_than_1m2?
          qty = 4
          qty = qty / 2 if taliumbulumbul?
          qty
        else
          top_bottom = @product.length / 1_000 * 2
          left_right = (@product.width / 1_000 - 1) * 2
          left_right = 0 if left_right&.negative?

          qty = top_bottom + left_right
          qty = qty / 2 if taliumbulumbul?
          qty
        end
      end
    end

    def finishing_paid
      return 0 if talispanduk? && greater_than_1m2?
      return 0 if taliumbulumbul? && greater_than_1m2?
      return 0 if mataayam? && finishing_quantity < mataayam_free

      finishing_quantity - finishing_free
    end

    def finishing_free
      return finishing_quantity if talispanduk? && greater_than_1m2?
      return finishing_quantity if taliumbulumbul? && greater_than_1m2?
      return mataayam_free if mataayam?

      0
    end

    def mataayam_free
      4
    end

    def finishing_price
      finishing_paid * price_per_unit
    end

    def price_per_unit
      finishing_tier.value
    end

    def production_time
      product_price[:finishing_hour] = finishing_tier.production_time.to_i
    end

    def set_description
      finishing_name = spec_value&.name
      finishing_name += ' (Gratis 4)' if mataayam?
      finishing_name += ' (Gratis jika luas material > 1m2)' if talispanduk? || taliumbulumbul?

      product_price[:finishing_description] = <<~DESC
        Jml Produk: <b>#{ number @product.quantity }</b>
        Ukuran Produk: <b>#{ number_decimal product_price[:width] / 1_000 }m x #{ number_decimal product_price[:length] / 1_000 }m</b>

        Jml #{finishing_name}: <b>#{ number finishing_quantity } - #{ number finishing_free } = #{ number finishing_paid }</b>
        Harga: <b>#{ idr price_per_unit }</b>

        <br /><u>Perhitungan:</u>
        Jml #{finishing_name} * Harga/pc
        <b>#{ number finishing_paid } * #{ idr price_per_unit }</b>
      DESC
    end

    def calculate
      return 0 unless ['mataayam', 'talispanduk', 'taliumbulumbul'].include?(spec_value&.code)

      if component.blank? || finishing_ratecard.blank? || @product.spec[:finishing].blank? || finishing_ratecard.deactive?
        @error = "[#{@product.printing_type}] Harga Finishing (#{@product.spec[:finishing]}) belum diisi."
        @product.prices.reject! { |p| p[:partner] == @partner && p[:machine] == @machine && p[:paper] == @paper }
        return -1
      end

      set_description
      product_price[:hours]           += production_time
      product_price[:finishing_price]  = finishing_price

      return finishing_price
    end
  end
end
