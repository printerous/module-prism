module Prism
  class Calculator::Corrugated::PostPressFormula < Calculator::PostPressFormula
    def ratecard
      @ratecard ||= Prism::PartnerRatecard.active_component.find_by(
        partner_id: @partner.id,
        printing_type: 'corrugated',
        version: 'ALL',
        'components.id': component.id
      )
    end
  end
end
