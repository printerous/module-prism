module Prism
  class Calculator::Digital::PrintCostFormula < Prism::Calculator::Digital::PostPressFormula
    COMPONENT_CODE = 'PRINT_COST'

    def component
      @component ||= if @product.print_side == 1
        Component.find_by(code: 'PRINT_PRICE_A3_1SIDE')
      else
        Component.find_by(code: 'PRINT_PRICE_A3_2SIDE')
      end
    end

    def ratecard
      @ratecard ||= PartnerRatecard.joins(:component).find_by(partner_id: @partner.id, printing_type: @product.printing_type, version: [@product.printing_type, 'ALL'], 'components.id': component&.id)
    end

    def price
      @price ||= product_price[:material_quantity] * tier.price
    end

    def production_time
      product_price[:print_cost_hour] = begin
        machine_ratecard = PartnerRatecard.joins(:component).find_by(partner_id: @partner.id, version: @machine.code, 'components.code': 'TIME_MACHINE_PREPARATION')
        machine_tier = machine_ratecard&.partner_ratecard_tiers&.first
        machine_prep = machine_tier&.value&.to_f || 0

        speed_ratecard = PartnerRatecard.joins(:component).find_by(partner_id: @partner.id, version: @machine.code, 'components.code': 'SPEED_PRINTING')
        speed_tier = speed_ratecard&.partner_ratecard_tiers&.first&.value
        return 0 if speed_tier.blank?

        speed_tier = 1 if speed_tier&.zero?
        speed_time = product_price[:material_quantity] / speed_tier * @product.print_side

        # naik mesin = material_quantity / 250
        # 2 menit * (4 * jumlah mata) * berapa kali naik
        cutting_time = 2/60.to_f * (4 * product_price[:impose_quantity]) * (product_price[:material_quantity] / 250)

        machine_prep + speed_time + cutting_time
      end
    end

    def set_description
      product_price["#{ @breakdown.code }_description"] = <<~DESC
        Jumlah Material: <b>#{ number product_price[:material_quantity] } lembar</b>
        Jml Sisi: <b>#{ @product.print_side }</b>
        Biaya Cetak/lembar: <b>#{ idr tier.price }</b>

        <br />Perhitungan:
        <b>Jumlah Material * Biaya Cetak/lembar</b>
        <b>#{ number product_price[:material_quantity] } * #{ idr tier.price }</b>
      DESC
    end

    def calculate
      if component.blank? || ratecard.blank?
        @error = "[#{@product.printing_type}] Print Cost belum diisi."
        @product.prices.reject! { |p| p[:partner] == @partner && p[:machine] == @machine && p[:paper] == @paper }
        return -1
      end

      set_description
      product_price[:hours]                      += production_time
      product_price["#{ @breakdown.code }_price"] = price

      return price
    end
  end

end
