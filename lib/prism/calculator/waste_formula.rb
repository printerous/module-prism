module Prism
  class Calculator::WasteFormula < Prism::Calculator::MaterialFormula
    COMPONENT_CODE   = 'PRINTING_WASTE'
    WASTE_PERCENTAGE = 0.2

    def component
      @component ||= begin
        @breakdown.relation || Component.find_by(code: COMPONENT_CODE)
      end
    end

    def ratecard
      @ratecard ||= PartnerRatecard.joins(:component).find_by(partner_id: @partner.id, version: 'ALL', 'components.id': component.id)
    end

    def tier
      @tier ||= begin
        ratecard_tiers = ratecard.partner_ratecard_tiers.order(:quantity_bottom)
        tier = ratecard_tiers.by_quantity(@product.quantity) ||
               ratecard_tiers.last
      end
    end

    def waste_percentage
      tier.price / 100.to_f
    end

    def waste_quantity
      @waste_quantity ||= waste_percentage * product_price[:material_quantity]
    end

    def waste_weight
      @waste_weight ||= (@paper.width * @paper.length / 1_000_000.to_f).ceil * @product.material.properties['gsm'].try(:to_f) / 1_000 * waste_quantity
    end

    def waste_price
      @waste_price ||= waste_percentage * material_price
    end

    def set_description
      product_price[:waste_description] = <<~DESC
        #{ waste_percentage * 100 }% * Biaya Material
        <b>#{ waste_percentage * 100 }% * #{ idr material_price }</b>
      DESC
    end

    def calculate
      return 0 if ratecard.blank? || @product.spec[:material].blank?

      set_description
      product_price[:waste_weight]   = waste_weight
      product_price[:waste_quantity] = waste_quantity
      product_price[:waste_price]    = waste_price
    # rescue
    #   0
    end

  end
end
