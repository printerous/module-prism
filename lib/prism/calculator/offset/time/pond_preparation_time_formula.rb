class Calculator::Offset::Time::PondPreparationTimeFormula < Calculator::Offset::Time::TimeFormula
  # input:
  # product: @product,
  # partner: @partner,
  # paper:   @paper,
  # machine: @machine
  COMPONENT_CODE = 'POND_BLADE'
  NAME = 'PondPreparationTime'

  def preparation_time
    @preparation_time ||= begin
      partner_ratecard_tier = partner_ratecard.partner_ratecard_tiers.last
      partner_ratecard_tier.properties['time_waiting'] || 0
    end
  end

  def set_description
    product_data["#{self.class::NAME.downcase}_description"] = <<~DESC
      Estimasi Persiapan Pond : <b>#{ preparation_time } jam</b>
    DESC
  end

  def perform
    if product_data.blank? || partner_ratecard.blank?
      @product.prices.reject! {|p| p[:partner] == @partner && p[:machine] == @machine && p[:paper] == @paper }
      @errors << "Ratecard waktu Persiapan Pond. Mohon isi terlebih dahulu data yang dibutuhkan"
      return 0
    end

    set_description

    time_name = "#{self.class::NAME.downcase}_time".to_sym
    product_data[time_name] = preparation_time

    return preparation_time
  end

end
