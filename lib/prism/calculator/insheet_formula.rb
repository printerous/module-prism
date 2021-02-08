# frozen_string_literal: true

module Prism
  class Calculator::InsheetFormula
    def initialize(**params)
      @partner           = params[:partner]
      @print_color       = params[:print_color]
      @print_side        = params[:print_side]
      @printing_mode     = params[:printing_mode]
      @material_quantity = params[:material_quantity]
      @product_spec      = params[:product_spec]
    end

    def calculate
      insheet_print.to_i + insheet_finishing.to_i
    end

    def insheet_print
      print_color = @print_color > 4 ? 4 : @print_color
      component = if @print_side == 2 && print_color > 0
                    Component.where("properties -> 'printing_mode' ? :printing_mode", printing_mode: @printing_mode).first
                  else
                    Component.where("properties ->> 'side' = :side", side: '1').first
                  end

      ratecard = component.partner_ratecard(@partner, "#{print_color}_warna")
      return 0 if ratecard.blank?

      tier = ratecard.tiers.by_quantity(@material_quantity)
      # Handle percentage
      return tier.value.to_f / 100 * @material_quantity if ratecard.unit == 'percentage'

      tier.value
    end

    def insheet_finishing
      finishing_spec_values = SpecValue.tagged_with(%w[LAMINATION FINISHING BINDING], any: true).collect(&:id)

      spec_values = @product_spec.values.collect do |value|
        next if finishing_spec_values.exclude?(value.to_i)

        SpecValue.find(value)
      end.reject(&:blank?)

      partner_ratecards = PartnerRatecard.joins(:component)
                                         .where(partner_id: @partner.id)
                                         .where('components.id IN (?)', spec_values.collect { |sv| sv.component&.id }.compact)

      partner_ratecards.sum do |partner_ratecard|
        component_code = partner_ratecard.component.properties['insheet_code']
        finising_ratecard = Component.find_by(code: component_code).partner_ratecard(@partner, 'jumlah_insheet')
        return 0 if finising_ratecard.blank?

        tier = finising_ratecard.tiers.by_quantity(@material_quantity)
        return 0 if tier.blank?
        # handle percentage
        return tier.value.to_f / 100 * @material_quantity if finising_ratecard.unit == 'percentage'

        return tier.value
      end
    end
  end
end
