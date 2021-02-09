require File.dirname(__FILE__) + '/pre_press_formula.rb'

module Prism
  class Calculator::PlateCostFormula < Calculator::PrePressFormula
    COMPONENT_CODE = 'PLATE_COST'

    # ================== SHORT PLATE ==================
    # get short component
    def short_component
      @short_component ||= Component.find_by(code: 'PLATE_SHORT_COST')
    end

    # get short run plate ratecard
    def short_ratecard
      @short_ratecard ||= PartnerRatecard.joins(:component).find_by(partner_id: @partner.id, 'components.id': short_component&.id, version: @machine.code)
    end

    # get short tiers
    def short_tier
      @short_tier ||= short_ratecard.tiers.first
    end

    # get short druk
    def short_druk
      @short_druk ||= short_tier.druk_quantity
    end

    # get short prices
    def short_price
      @short_price ||= short_tier.value
    end

    # =================== LONG PLATE ===================
    # get long component
    def long_component
      @long_component ||= Component.find_by(code: 'PLATE_LONG_COST')
    end

    # get short run plate ratecard
    def long_ratecard
      @long_ratecard ||= PartnerRatecard.joins(:component).find_by(partner_id: @partner.id, 'components.id': long_component&.id, version: @machine.code)
    end

    # get long_tier tiers
    def long_tier
      @long_tier ||= long_ratecard.tiers.first
    end

    # get long druk
    def long_druk
      @long_druk ||= long_tier.druk_quantity
    end

    # get long price
    def long_price
      @long_price ||= long_tier.value
    end

    # calculate total druk
    def total_druk
      product_price[:total_material_quantity] * @product.print_side
    end

    # get druk price based on total druk
    # F jumlah druk yg akan di cetak plat tersebut > dari max_druk plat short run , gunakan plat long run. -> SIMPLE logic
    def druk_price
      price = short_price
      price = long_price if total_druk > short_druk
      @druk_price ||= price
    end

    def druk_amount
      amount = short_druk
      amount = long_druk if total_druk > short_druk
      @druk_amount ||= amount
    end

    def druk_type
      type = 'Short Run'
      type = 'Long Run' if total_druk > short_druk
      @druk_type ||= type
    end

    # plate count based on number of druk
    def plate_count
      druk = total_druk > short_druk ? long_druk : short_druk
      @plate_count ||= (total_druk.to_f / druk).ceil
    end

    def production_time
      0
    end

    def plate_price
      @plate_price ||= druk_price * @product.print_color * product_price[:plate_design] * plate_count
    end

    def set_description
      product_price["#{ self.class::COMPONENT_CODE.downcase }_description"] = <<~DESC
        Biaya Plat <b>#{ druk_type }</b>: <b>#{ idr druk_price }</b>
        Jumlah Druk Plat <b>#{ druk_type }</b>: <b>#{ number druk_amount }</b>
        Jumlah Druk: <b>#{ number total_druk }</b>

        Jml Design Plat: <b>#{ product_price[:plate_design] }</b>
        Jml Muka: <b>#{ product_price[:printing_mode].impose_count }</b>
        Jml Warna Depan: <b>#{ @product.colors[0] }</b>
        Jml Warna Belakang: <b>#{ @product.colors[1] }</b>
        Jml Sisi: <b>#{ @product.print_side }</b>
        Jml Plat druk : <b>#{ plate_count }</b>

        <br />Perhitungan #{ product_price[:printing_mode].mode.present? ? product_price[:printing_mode].mode : ''  }:
        Harga Plat berdasarkan Jumlah Druk/warna * Jumlah Warna * Jumlah Design Plat * Jml Plat Druk
        <b>#{ idr druk_price }</b> * <b>#{ @product.print_color }</b> * <b>#{ product_price[:plate_design] }</b> * <b>#{ plate_count }</b>
      DESC
    end

    def calculate
      if short_component.blank? || long_component.blank? || short_ratecard.blank? || long_ratecard.blank? ||
        short_tier.blank? || long_tier.blank? || short_druk.zero? || long_druk.zero?
        @error = "[#{@product.printing_type}] Harga Plat belum diisi."
        @product.prices.reject! { |p| p[:partner] == @partner && p[:machine] == @machine && p[:paper] == @paper }
        return -1
      end

      set_description

      product_price[:hours]    += production_time
      price_name                = "#{ self.class::COMPONENT_CODE.downcase }_price".to_sym
      product_price[price_name] = plate_price

      return plate_price
    end
  end

end
