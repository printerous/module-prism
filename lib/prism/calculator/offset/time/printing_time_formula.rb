class Calculator::Offset::Time::PrintingTimeFormula < Calculator::Offset::Time::TimeFormula
  NAME = 'PrintingTime'
  COMPONENTS = ['TIME_PLATE_PREPARATION','TIME_MACHINE_PREPARATION','SPEED_PRINTING']

  # get total material quantity
  def total_material_quantity
    @total_material_quantity
  end

  # get time components for machine
  def components
    @components ||= Component.where(code: COMPONENTS)
  end

  # get all value (time/hour) for all time machine component
  def machine_times
    @machine_times ||= begin
      values = {}

      components.each do |component|
        ratecard = PartnerRatecard.joins(:component).find_by(partner_id: @partner.id, version: @machine.code, 'components.id': component.id)
        break if ratecard.blank?
        tier = ratecard.tiers.first
        value = tier.try(:value)
        break if value.blank?

        values[component.code] = value
      end

      values
    end
  end

  # get material ratecard
  def material_ratecard
    @material_ratecard ||= PartnerRatecard.joins(:component).find_by(partner_id: @partner.id, version: @paper.plano.code, 'components.id': @product.material.id)
  end

  # get material waiting time
  def material_time
    return nil if material_ratecard.blank?
    @material_time ||= material_ratecard.properties['waiting_time'].to_i
  end

  # get machine & plate preparation time
  def machine_preparation_time
    machine_preparation_components = ['TIME_PLATE_PREPARATION','TIME_MACHINE_PREPARATION']
    @machine_preparation_time ||= begin
      component_times = machine_times.select{|key, value| machine_preparation_components.include?(key)}
      time = component_times.inject(0) {|sum, t| sum += t[1]}
      time
    end
  end

  # get machine printing Time
  # formula : total_material_quantity / printing speed (lembar/jam) * jumlah sisi
  def machine_printing_time
    @machine_printing_time ||= begin
      time = (total_material_quantity.to_f / machine_times['SPEED_PRINTING']) * @product.print_side
      time
    end
  end

  # calculate total printing Time
  # formula : (max between machine_preparation_time and material_time) + machine_printing_time
  def printing_time
    @printing_time ||= [machine_preparation_time, material_time.to_f].max + machine_printing_time
  end

  def set_description
    product_data["#{self.class::NAME.downcase}_description"] = <<~DESC

      Estimasi Pembuatan Plat : <b>#{machine_times['TIME_PLATE_PREPARATION']} jam</b>
      Estimasi Persiapan Mesin : <b>#{machine_times['TIME_MACHINE_PREPARATION']} jam</b>
      Estimasi Kecepatan Cetak : <b>#{machine_times['SPEED_PRINTING']} lembar/jam</b>

      Estimasi Persiapan Material : <b>#{material_time} jam</b>

      Persiapan Plat & Mesin : <b>#{machine_preparation_time} jam</b>
      Jumlah Lembar Material : <b>#{total_material_quantity}</b>
      Jumlah Sisi : <b>#{@product.print_side}</b>
      Waktu cetak (Jml Lembar Material / KecepatanLembar/jam) x Jumlah Sisi: <b>#{ number_decimal machine_printing_time } jam</b>

      <br /><u>Perhitungan: (#{ product_data[:printing_mode].mode })</u>
      Nilai MAX antara <b>Persiapan Plat & Mesin</b> dengan <b>Persiapan Material</b> + <b>Waktu Cetak</b>
      <b>MAX(#{machine_preparation_time}, #{material_time}) + #{ number_decimal printing_time }</b>
    DESC
  end

  def perform
    if (machine_times.size != COMPONENTS.size) || material_time.blank? || product_data.blank? || validate_speed
      @product.prices.reject! {|p| p[:partner] == @partner && p[:machine] == @machine && p[:paper] == @paper }
      @errors << "Ratecard Persiapan Mesin dan Plat tidak ditemukan atau data Salah. Mohon isi terlebih dahulu data yang dibutuhkan"
      return 0
    end

    set_description

    time_name = "#{self.class::NAME.downcase}_time".to_sym
    product_data[time_name] = printing_time

    return printing_time
  end

  def validate_speed
    return false if  machine_times['SPEED_PRINTING'].blank?
    machine_times['SPEED_PRINTING'].zero?
  end
end
