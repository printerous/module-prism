module Prism
  class Calculator::LaminationFormula < Calculator::PostPressFormula
    def component
      @component ||= begin
        spec_key   = @breakdown.relation
        value_id   = @product._spec[spec_key.id.to_s]
        spec_value = SpecValue.find_by(id: value_id)
        spec_value.component
      end
    end

    def tier
      @tier ||= begin
        ratecard_tiers = ratecard.partner_ratecard_tiers.order(:quantity_bottom)
        tier = ratecard_tiers.by_quantity(finishing_quantity) ||
               ratecard_tiers.first
      end
    end

    def insheet_component
      Component.find_by(code: component.properties['insheet_code'])
    end

    def insheet_a_ratecard
      @insheet_a_ratecard ||= PartnerRatecard.active_component.find_by(
        partner_id: @partner.id,
        version: 'jumlah_insheet',
        'components.id': insheet_component.id
      )
    end

    def insheet_a_tier
      @insheet_tier ||= begin
        insheet_a_ratecard_tiers = insheet_a_ratecard.partner_ratecard_tiers.order(:quantity_top)
        selected = insheet_a_ratecard_tiers.by_quantity(product_price[:material_quantity]) || insheet_a_ratecard_tiers.first
        selected
      end
    end

    def insheet_a_value
      @insheet_a_value ||= insheet_a_tier.value rescue 0
    end

    # ----------------------------------------------------- COMPONENT B / BELAKANG -------------------------------------------------------

    def component_b
      @component_b ||= begin
        spec_key   = SpecKey.find_by(code: :lamination_b)
        value_id   = @product._spec[spec_key.id.to_s]
        spec_value = SpecValue.find_by(id: value_id)
        spec_value.component
      rescue
        nil
      end
    end

    def ratecard_b
      @ratecard_b ||= PartnerRatecard.joins(:component).find_by(partner_id: @partner.id, version: 'ALL', 'components.id': component_b.id)
    end

    def tier_b
      @tier_b ||= begin
        ratecard_tiers = ratecard_b.partner_ratecard_tiers.order(:quantity_bottom)
        tier = ratecard_tiers.by_quantity(finishing_quantity) ||
               ratecard_tiers.first
      rescue
        PartnerRatecardTier.new(price: 0)
      end
    end

    def insheet_b_component
      Component.find_by(code: component_b.properties['insheet_code'])
    end

    def insheet_b_ratecard
      @insheet_b_ratecard ||= PartnerRatecard.active_component.find_by(
        partner_id: @partner.id,
        version: 'jumlah_insheet',
        'components.id': insheet_b_component.id
      )
    end

    def insheet_b_tier
      @insheet_b_tier ||= begin
        insheet_b_ratecard_tiers = insheet_b_ratecard.partner_ratecard_tiers.order(:quantity_top)
        selected = insheet_b_ratecard_tiers.by_quantity(product_price[:material_quantity]) || insheet_b_ratecard_tiers.first
      end
    end

    def insheet_b_value
      @insheet_b_value ||= insheet_b_tier.value rescue 0
    end

    def finishing_quantity
      @finishing_quantity ||= product_price[:material_quantity] + insheet_a_value + insheet_b_value
    end

    def price
      @price ||= begin
        value = @paper.width * @paper.length / 100 * finishing_quantity * tier.price
        if component_b.present?
          value += @paper.width * @paper.length / 100 * finishing_quantity * tier_b.price
        end

        [ratecard.price_minimum, value].max
      end
    end

    def production_time
      0
    end

    def set_description
      product_price["#{ @breakdown.code }_description"] = <<~DESC
        Min Price: <b>#{ idr ratecard.price_minimum }</b>
        Paper Width: <b>#{ @paper.width / 10 }cm</b>
        Paper Length: <b>#{ @paper.length / 10 }cm</b>
        Total Material: <b>#{ number finishing_quantity }</b>
        ---
        Laminasi Depan: <b>#{ component.name }</b>
        Harga Laminasi Depan/cm2: <b>#{ idr tier.price }</b>
        #{
          if component_b.present?
            "---
            Laminasi Belakang: <b>#{ component_b.name }</b>
            Harga Laminasi Belakang/cm2: <b>#{ idr tier_b.price }</b>"
          end
        }

        <br />Perhitungan:
        Nilai MAX antara <b>Min Price</b> dengan <b>Luas Kertas (cm2) * Total Material * Harga Laminasi/cm2 (Depan + Belakang)</b>
        <b>MAX</b>(#{ idr ratecard.price_minimum },
          <i>Depan</i> <b>((#{ @paper.width / 10.to_f } * #{ @paper.length / 10.to_f}) * #{ number finishing_quantity } * #{ idr tier.price })</b>
          #{
            if component_b.present?
              "<i>+ Belakang</i> <b>((#{ @paper.width / 10.to_f } * #{ @paper.length / 10.to_f}) * #{ number finishing_quantity } * #{ idr tier_b.price })</b>"
            end
          }
      DESC
    end

    def calculate
      is_none = @product.spec[:lamination]&.to_s&.upcase&.strip == 'NONE'
      if @product.spec[:lamination].blank? || is_none
        return 0
      end

      if @product.spec[:lamination].present? && (component.blank? || ratecard.blank? || ratecard.partner_component.deactive?)
        @error = "[#{@product.printing_type}] Harga Laminasi belum diisi."
        @product.prices.reject! { |p| p[:partner] == @partner && p[:machine] == @machine && p[:paper] == @paper }
        return -1
      end

      set_description

      product_price["#{ @breakdown.code }_price"] = price

      return price
    end
  end

end
