module Prism
  class Calculator::PrePressFormula
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

    def component
      Component.find_by(code: self.class::COMPONENT_CODE) || @breakdown.relation
    end

    def ratecard
      @ratecard ||= PartnerRatecard.joins(:component).find_by(partner_id: @partner.id, 'components.id': component.id, version: @machine.code)
    end

    def tier
      @tier ||= begin
        ratecard_tiers = ratecard.partner_ratecard_tiers.order(:quantity_bottom)
        tier = ratecard_tiers.by_quantity(@product.quantity) ||
               ratecard_tiers.last
      end
    end

    def product_price
      @product_price ||= @product.prices.find {|p| p[:partner] == @partner && p[:machine] == @machine && p[:paper] == @paper }
    end

    def price
      @price ||= [ratecard.price_minimum, tier.price].max
    end

    def production_time
      tier.production_time || 0
    end

    def calculate
      if component.blank? || ratecard.blank?
        @error = "Harga (#{self.class::COMPONENT_CODE}) belum diisi."
        @product.prices.reject! { |p| p[:partner] == @partner && p[:machine] == @machine && p[:paper] == @paper }
        return -1
      end

      set_description

      price_name                = "#{ self.class::COMPONENT_CODE.downcase }_price".to_sym
      product_price[:hours]    += production_time
      product_price[price_name] = price

      return price
    end
  end

end
