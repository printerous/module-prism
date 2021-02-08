class Calculator::Corrugated::PrintCostFormula < Calculator::Corrugated::PostPressFormula
  COMPONENT_CODE = 'PRINT_COST'

  def component_a
    @component_a ||= Component.find_by(code: "PRINT_COST_CORRUGATED_#{@product.colors.first}")
  end

  def ratecard_a
    @ratecard_a ||= PartnerRatecard.joins(:component).find_by(partner_id: @partner.id, version: 'ALL', 'components.id': component_a&.id)
  end

  def tier_a
    @tier_a ||= begin
      ratecard_tiers = ratecard_a.partner_ratecard_tiers.order(:quantity_bottom)
      ratecard_tiers.by_quantity(@product.quantity) || ratecard_tiers.first
    end
  end

  def component_b
    @component_b ||= Component.find_by(code: "PRINT_COST_CORRUGATED_#{@product.colors.last}")
  end

  def ratecard_b
    @ratecard_b ||= PartnerRatecard.joins(:component).find_by(partner_id: @partner.id, version: 'ALL', 'components.id': component_b&.id)
  end

  def tier_b
    @tier_b ||= begin
      ratecard_tiers = ratecard_b.partner_ratecard_tiers.order(:quantity_bottom)
      ratecard_tiers.by_quantity(@product.quantity) || ratecard_tiers.first
    end
  end

  def price
    @price ||= @product.quantity * tier_a.price
  end

  def production_time
    product_price[:print_cost_hour] = 0
  end

  def set_description
    product_price["#{ @breakdown.code }_description"] = <<~DESC
      Jumlah Produk: <b>#{ number @product.quantity }</b>
      Jml Sisi: <b>#{ @product.print_side }</b>
      Biaya Cetak #{@product.color} Warna: <b>#{ idr tier_a.price }</b>

      <br />Perhitungan:
      <b>Jumlah Produk * Biaya Cetak</b>
      <b>#{ number @product.quantity } * #{ idr tier_a.price }</b>
    DESC
  end

  def calculate
    if ratecard_a.blank?
      @error = "[#{@product.printing_type}] Print Cost belum diisi."
      @product.prices.reject! { |p| p[:partner] == @partner }
      return -1
    end

    set_description
    product_price[:hours]                      += production_time
    product_price["#{ @breakdown.code }_price"] = price

    return price
  end
end
