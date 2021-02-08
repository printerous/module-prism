module Prism
  class Calculator::PrintingCostFormula < Calculator::PostPressFormula
    COMPONENT_CODE = 'PRINTING_COST_MINIMUM'

    def component_minimum
      @minimum_component ||= Component.find_by(code: 'PRINTING_COST_MINIMUM')
    end

    def component_additional
      @additional_component ||= Component.find_by(code: 'PRINTING_COST_ADDITIONAL')
    end

    # Get PRINTING_COST_MINIMUM ratecard
    def minimum_ratecard
      @minimum_ratecard ||= PartnerRatecard.joins(:component).find_by(partner_id: @partner.id, version: @machine.code, 'components.id': component_minimum.id)
    end
    # Get PRINTING_COST_MINIMUM tier
    def minimum_tier
      @minimum_tier ||= minimum_ratecard.tiers.first
    end

    # Get PRINTING_COST_MINIMUM price
    def minimum_price
      @minimum_price ||= minimum_tier.value
    end

    # Get PRINTING_COST_MINIMUM druk
    def minimum_druk
      @minimum_druk ||= minimum_tier.druk_quantity
    end

    # if total_druk more than druk minimum then get PRINTING_COST_ADDITIONAL ratecard
    def additional_ratecard
      @additional_ratecard ||= PartnerRatecard.joins(:component).find_by(partner_id: @partner.id, version: @machine.code, 'components.id': component_additional.id)
    end

    # get PRINTING_COST_ADDITIONAL tiers
    def additional_tiers
      @additional_tiers ||= additional_ratecard.tiers
    end

    # find PRINTING_COST_ADDITIONAL tiers where remaining druk
    def additional_tier
      @additional_tier ||= additional_tiers.by_quantity(leftover_druk) || additional_tiers.last
    end

    def additional_price
      @additional_price ||= additional_tier.value
    end

    def additional_druk
      @additional_druk ||= additional_tier.druk_quantity
    end

    # calculate total druk
    def total_druk
      product_price[:total_material_quantity] * @product.print_side
    end

    # calculate leftover druk
    def leftover_druk
      return 0 if total_druk < minimum_druk
      total_druk - minimum_druk
    end

    # ========================== TIER MODE ==========================
    # calculate additional price based on leftover_druk
    def tier_leftover_price
      return 0 if leftover_druk.zero?
      total = 0
      leftover = leftover_druk
      tiers = additional_tiers

      while leftover > 0
        tier = tiers.first

        if leftover - tier.druk_quantity < 0
          total += leftover * tier.value
        else
          total += tier.druk_quantity * tier.value
        end

        leftover = leftover - tier.druk_quantity
        tiers = tiers.drop(1) if tiers.size > 1
      end

      total
    end

    def tier_leftover_description
      @leftover_description ||= begin
        return [] if leftover_druk.zero?
        total = 0
        leftover = leftover_druk
        tiers = additional_tiers
        description = []

        while leftover > 0
          tier = tiers.first

          if leftover - tier.druk_quantity < 0
            description << "Druk Tambahan * Harga Tambahan: <b>#{ number leftover } * #{ idr tier.value }</b>"
          else
            description << "Druk Tambahan * Harga Tambahan: <b>#{ number tier.druk_quantity } * #{ idr tier.value }</b>"
          end

          leftover = leftover - tier.druk_quantity

          tiers = tiers.drop(1) if tiers.size > 1
        end
        description
      end
    end

    # ========================= FIXED MODE =========================
    def fixed_leftover_price
      return 0 if leftover_druk.zero?
      additional_price * leftover_druk
    end

    def price
      @price ||= @product.print_color * product_price[:plate_design] * (minimum_price + fixed_leftover_price)
    end

    def set_description
      product_price["#{ @breakdown.code }_description"] = <<~DESC
        Min Price: <b>#{ idr minimum_price }</b>
        Jml Minimum Druk: <b>#{ minimum_druk } druk</b>
        Jml Warna: <b>#{ @product.print_color }</b>
        Jml Design Plat: <b>#{ product_price[:plate_design] }</b>

        Total Material: <b>#{ number product_price[:total_material_quantity] } lembar </b>
        Jml Sisi: <b>#{ @product.print_side }</b>
        Total Druk: <b>#{ number total_druk } druk</b>

        Jml Druk Tambahan (Total Druk - Jml Minimum Druk): <b>#{ number leftover_druk } druk</b>
        Biaya Cetak Tambahan : <b>#{ idr additional_price }/druk</b>
      DESC

      product_price["#{ @breakdown.code }_description"] += <<~DESC
        <br /><u>Perhitungan #{ product_price[:printing_mode].mode.present? ? product_price[:printing_mode].mode : ''  }:</u>
        Jml Warna * Jml Design Plat * (Min Price + Tier Tambahan)
        <b>#{ @product.print_color } * #{ product_price[:plate_design] } * (#{ idr minimum_price } + (#{ idr additional_price } * #{ number leftover_druk }))</b>
      DESC
    end

    def calculate
      if component_minimum.blank? || minimum_ratecard.blank? || minimum_tier.blank? || additional_ratecard.blank? || additional_tier.blank? ||
        minimum_price.blank? || additional_price.blank?
        @error = "[#{@product.printing_type}] Printing Cost belum diisi."
        @product.prices.reject! { |p| p[:partner] == @partner && p[:machine] == @machine && p[:paper] == @paper }
        return -1
      end

      set_description

      product_price[:hours] += production_time
      product_price["#{ @breakdown.code }_price"] = price

      return price
    end

    # ==============================
    def production_time
      product_price["#{ @breakdown.code }_hour"] = minimum_tier.production_time + tier.production_time rescue 0
    end
  end

end
