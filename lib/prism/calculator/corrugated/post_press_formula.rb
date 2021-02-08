class Calculator::Corrugated::PostPressFormula < Calculator::PostPressFormula
  def ratecard
    @ratecard ||= PartnerRatecard.active_component.find_by(
      partner_id: @partner.id,
      printing_type: 'corrugated',
      version: 'ALL',
      'components.id': component.id
    )
  end
end