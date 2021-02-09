# frozen_string_literal: true
require File.dirname(__FILE__) + '/../digital.rb'

module Prism
  class Calculator::Digital::PostPressFormula < Prism::Calculator::PostPressFormula
    def ratecard
      @ratecard ||= PartnerRatecard.active_component.find_by(
        partner_id: @partner.id,
        printing_type: @product.printing_type,
        version: [@product.printing_type, 'ALL'],
        'components.id': component.id
      )
    end
  end
end
