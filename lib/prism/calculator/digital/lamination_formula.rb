module Prism
  class Calculator::Digital::LaminationFormula < Prism::Calculator::Digital::PostPressFormula
    def spec_value
      @spec_value ||= begin
        spec_key   = @breakdown.relation
        value_id   = @product._spec[spec_key.id.to_s]
        spec_value = SpecValue.find_by(id: value_id)
      end
    end

    def component
      @component ||= spec_value.component_for('digital', { side: product_price[:print_side] })
    end

    def ratecard
      @ratecard ||= PartnerRatecard.joins(:component).find_by(partner_id: @partner.id, printing_type: @product.printing_type, version: [@product.printing_type, 'ALL'], 'components.id': component&.id)
    end

    def tier
      @tier ||= begin
        ratecard_tiers = ratecard.partner_ratecard_tiers.order(:quantity_bottom)
        tier = ratecard_tiers.by_quantity(finishing_quantity) ||
               ratecard_tiers.first
      end
    end

    def finishing_quantity
      @finishing_quantity ||= product_price[:material_quantity]
    end

    def price
      @price ||= finishing_quantity * tier.price
    end

    def production_time
      product_price[:lamination_hour] = begin
        speed = ratecard.properties['production_speed']&.to_f || 0

        if speed.zero?
          0
        else
          product_price[:material_quantity] / speed / product_price[:print_side]
        end
      end
    end

    def set_description
      product_price["#{ @breakdown.code }_description"] = <<~DESC
        Jenis Laminasi: <b>#{ spec_value.name }</b>
        Harga Laminasi/lembar (#{ product_price[:print_side] } sisi): <b>#{ idr tier.price }</b>

        <br />Perhitungan:
        Jml Material * Harga Laminasi/lembar (#{ product_price[:print_side] } sisi)
        <b>#{ number finishing_quantity } * #{ idr tier.price }</b>
      DESC
    end

    def calculate
      is_none = @product.spec[:lamination]&.to_s&.upcase&.strip == 'NONE'
      if @product.spec[:lamination].blank? || is_none
        return 0
      end

      if @product.spec[:lamination].present? && (component.blank? || ratecard.blank?)
        @error = "[#{@product.printing_type}] Harga Laminasi belum diisi."
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
