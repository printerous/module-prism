class Calculator::Offset::Time::FoldingTimeFormula < Calculator::Offset::Time::TimeFormula
  COMPONENT_CODE = 'FOLDING'
  NAME = 'FoldingTime'

  def set_description
    product_data["#{self.class::NAME.downcase}_description"] = <<~DESC
      Jumlah Material : <b>#{ number @total_material_quantity }</b>
      Kecepatan Folding : <b>#{ number speed } lembar/jam</b>
      </br>
      Perhitungan :
      Total Material / Kecepatan Folding
      <b>#{ @total_material_quantity } / #{ speed } = #{time}</b>
    DESC
  end

  def speed
    @speed ||= begin
      tier = partner_ratecard.partner_ratecard_tiers.by_quantity(@total_material_quantity)
      tier.production_time || 1
    end
  end

  def time
    @time ||= @total_material_quantity / speed
  end

  def perform
    is_none = @product&.spec[:folding]&.to_s&.upcase&.casecmp('NONE')&.zero?
    return 0 if is_none

    if product_data.blank? || partner_ratecard.blank?
      @product.prices.reject! {|p| p[:partner] == @partner && p[:machine] == @machine && p[:paper] == @paper }
      @errors << "Ratecard waktu Folding. Mohon isi terlebih dahulu data yang dibutuhkan"
      return 0
    end

    set_description

    time_name = "#{self.class::NAME.downcase}_time".to_sym
    product_data[time_name] = time

    return time
  end

end
