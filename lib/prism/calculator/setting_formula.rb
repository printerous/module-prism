module Prism
  class Calculator::SettingFormula < Prism::Calculator::PrePressFormula
    COMPONENT_CODE = 'SETTING'

    def production_time
      product_price["#{ @breakdown.code }_hour"] = tier.production_time || 0 #change production time
    end

    def ratecard
      @ratecard = PartnerRatecard.joins(:component).find_by(partner_id: @partner.id, version: 'ALL', 'components.id': component.id)
    end

    def set_description
      product_price["#{ @breakdown.code }_description"] = <<~DESC
        Biaya Setting/project: <b>#{ idr tier.price }</b>
      DESC
    end

    def price
      tier.value
    end
  end

end
