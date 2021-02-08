module Prism
  class Calculator::Offset::Time::TimeFormula
    include ActionView::Helpers::NumberHelper
    include Prism::ApplicationHelper

    attr_accessor :errors

    def initialize(**params)
      @product                 = params[:product]
      @partner                 = params[:partner]
      @machine                 = params[:machine]
      @paper                   = params[:paper]
      @total_material_quantity = params[:total_material_quantity]
      @errors                  = []
      @results                 = {}
    end

    def product_data
      @product_data ||= @product.prices.find {|p| p[:partner] == @partner && p[:machine] == @machine && p[:paper] == @paper }
    end

    def component
      @component ||= Component.find_by code: self.class::COMPONENT_CODE
    end

    def partner_ratecard
      @partner_ratecard ||= PartnerRatecard.joins(:component).find_by(partner_id: @partner.id, version: 'ALL', 'components.id': component.id)
    end
  end

end
