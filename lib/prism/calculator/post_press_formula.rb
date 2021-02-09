module Prism
  class Calculator::PostPressFormula
    include ActionView::Helpers::NumberHelper
    include Prism::ApplicationHelper
    attr_reader :error

    COMPONENT_CODE = 'POST_PRESS'

    def initialize(**params)
      @breakdown = params[:breakdown]
      @product   = params[:product]
      @partner   = params[:partner]
      @machine   = params[:machine]
      @paper     = params[:paper]
      @error     = nil
    end

    def price_name
      'post_press'
    end

    def component
      @breakdown.relation || Component.find_by(code: self.class::COMPONENT_CODE)
    end

    def ratecard
      @ratecard ||= PartnerRatecard.active_component.find_by(
        partner_id: @partner.id,
        version: 'ALL',
        'components.id': component.id
      )
    end

    def tier
      @tier ||= begin
        ratecard_tiers = ratecard.partner_ratecard_tiers.order(:quantity_bottom)
        ratecard_tiers.by_quantity(@product.quantity) || ratecard_tiers.first
      end
    end

    def product_price
      @product_price ||= @product.prices.find {|p| p[:partner] == @partner && p[:machine] == @machine && p[:paper] == @paper }
    end

    def printing_quantity
      @printing_quantity ||= product_price[:material_quantity] + product_price[:waste_quantity] rescue product_price[:material_quantity]
    end

    def insheet_component
      Component.find_by(code: self.class::INSHEET_CODE)
    end

    def insheet_ratecard
      @insheet_ratecard ||= PartnerRatecard.active_component.find_by(
        partner_id: @partner.id,
        version: 'jumlah_insheet',
        'components.id': insheet_component.id
      )
    end

    def insheet_tier
      @insheet_tier ||= begin
        insheet_ratecard_tiers = insheet_ratecard.partner_ratecard_tiers.order(:quantity_bottom)
        selected = insheet_ratecard_tiers.by_quantity(product_price[:material_quantity]) || insheet_ratecard_tiers.first
      end
    end

    def insheet_quantity
      @insheet_quantity ||= insheet_tier.value rescue 0
    end

    def finishing_quantity
      @finishing_quantity ||= product_price[:material_quantity] + insheet_quantity
    end

    def printing_weight
      @printing_weight ||= product_price[:material_weight] + product_price[:waste_weight]
    end

    def price
      @price ||= @product.print_side * printing_quantity * tier.price
    end

    def set_description
      product_price["#{ price_name }_description".to_sym] = ''
    end

    def calculate
      return 0
      set_description

      product_price[:hours]           += tier&.production_time || 0
      product_price[price_name.to_sym] = [ratecard.price_minimum, component_price].max
    # rescue
    #   0
    end
  end
end
