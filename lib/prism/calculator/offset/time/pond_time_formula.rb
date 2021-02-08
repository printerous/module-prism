class Calculator::Offset::Time::PondTimeFormula < Calculator::Offset::Time::TimeFormula

  # input:
  # product: @product,
  # partner: @partner,
  # paper:   @paper,
  # machine: @machine
  COMPONENT_CODE = 'POND_SERVICE'
  NAME = 'PondTime'

  def set_description
    product_data["#{self.class::NAME.downcase}_description"] = <<~DESC
      Jumlah Material : #{ number @total_material_quantity }
      Kecepatan Pond : #{ number partner_ratecard_tier.production_time.to_i} lembar/jam

      </br>
      Perhitungan :
      Jumlah Material / Kecepatan Pond
      <b>#{ number product_data[:quantity]} / #{ number partner_ratecard_tier.production_time.to_i}</b>
    DESC
  end

  def partner_ratecard_tier
    @partner_ratecard_tier ||= partner_ratecard.partner_ratecard_tiers.last
  end

  def perform
    if product_data.blank? || partner_ratecard.blank?
      @product.prices.reject! {|p| p[:partner] == @partner && p[:machine] == @machine && p[:paper] == @paper }
      @errors << "Ratecard waktu Pond. Mohon isi terlebih dahulu data yang dibutuhkan"
      return 0
    end

    time = (@total_material_quantity.to_i / partner_ratecard_tier.production_time.to_i).ceil

    set_description

    time_name = "#{self.class::NAME.downcase}_time".to_sym
    product_data[time_name] = time

    time
  end

end
