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

    def finishing_quantity
      product_price[:finishing_quantity] = begin
        top_bottom = @product.length / 1_000 * 2
        left_right = (@product.width / 1_000 - 1) * 2
        left_right = 0 if left_right&.negative?

        top_bottom + left_right
      end
    end

    def finishing_paid
      return 0 if finishing_quantity < finishing_free

      finishing_quantity - finishing_free
    end

    def finishing_free
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
      product_price[:finishing_description] = <<~DESC
        Jml Produk: <b>#{ number @product.quantity }</b>
        Ukuran Produk: <b>#{ number_decimal product_price[:paper_width] / 1_000 }m x #{ number_decimal @product.print_length / 1_000 }m</b>
        Jml Mata Ayam (Gratis 4): <b>#{ number finishing_quantity } - #{ number finishing_free } = #{ number finishing_paid }</b>
        Harga: <b>#{ idr price_per_unit }</b>

        <br /><u>Perhitungan:</u>
        Jml Mata Ayam * Harga/pc
        <b>#{ number finishing_paid } * #{ idr price_per_unit }</b>
      DESC
    end

    def calculate
      return 0 if spec_value&.code != 'mataayam'

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
