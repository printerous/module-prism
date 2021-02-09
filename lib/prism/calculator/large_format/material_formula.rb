module Prism
  class Calculator::LargeFormat::MaterialFormula
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

    def product_price
      @product_price ||= @product.prices.find {|p| p[:partner] == @partner && p[:machine] == @machine && p[:paper] == @paper }
    end

    def material_ratecard
      Prism::PartnerRatecard.joins(:component).find_by(partner_id: @partner.id, version: 'LARGE_FORMAT', 'components.id': @product.material.id)
    end

    def material_tier
      material_ratecard.tiers.last
    end

    def material_price
      [product_price[:material_area] * price_per_meter * @product.quantity, price_per_meter].max
    end

    def price_per_meter
      material_tier.value
    end

    def material_length
      @product.print_length * @product.quantity
    end

    def production_time
      product_price[:material_hour] = begin
        machine_ratecard = Prism::PartnerRatecard.joins(:component).find_by(partner_id: @partner.id, version: @machine.code, 'components.code': 'TIME_MACHINE_PREPARATION')
        machine_tier     = machine_ratecard&.partner_ratecard_tiers&.first
        machine_prep     = machine_tier&.value&.to_f || 0

        speed_ratecard = Prism::PartnerRatecard.joins(:component).find_by(partner_id: @partner.id, version: @machine.code, 'components.code': 'SPEED_PRINTING')
        speed_tier     = speed_ratecard&.partner_ratecard_tiers&.first&.value
        speed_tier     = 1 if speed_tier.nil?
        speed_tier     = 1 if speed_tier.zero?
        speed_time     = material_length / 1_000 / speed_tier

        material_hour  = material_tier.production_time.to_i

        machine_prep + speed_time + material_hour
      end
    end

    def set_description
      product_price[:material_description] = <<~DESC
        Jml Produk: <b>#{ number @product.quantity }</b>
        Ukuran Produk: <b>#{ number_decimal @product.width / 1_000.to_f }m x #{ number_decimal @product.length / 1_000.to_f }m</b>
        Ukuran Material: <b>#{ number_decimal @product.print_width / 1_000 }m x #{ number_decimal @product.print_length / 1_000 }m</b>
        Luas Material: <b>#{ number_decimal product_price[:material_area] } m2 (minimum 1m2)</b>
        Harga/m: <b>#{ idr price_per_meter }</b>

        <br /><u>Perhitungan:</u>
        Luas Material * Harga/m
        <b>#{ number_decimal [product_price[:material_area], 1].max } * #{ idr price_per_meter }</b>
      DESC
    end

    def calculate
      if @product.material.blank? || material_ratecard.blank? || @product.spec[:material].blank? || material_ratecard.deactive?
        @error = "[#{@product.printing_type}] Harga Material (#{@product.material&.name}) belum diisi."
        @product.prices.reject! { |p| p[:partner] == @partner && p[:machine] == @machine && p[:paper] == @paper }
        return -1
      end

      set_description
      product_price[:hours]           += production_time
      product_price[:material_price]  = material_price

      return material_price
    end
  end

end
