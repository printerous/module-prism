require File.dirname(__FILE__) + '/time_formula.rb'

module Prism
  class Calculator::Offset::Time::LaminationTimeFormula < Prism::Calculator::Offset::Time::TimeFormula
    # COMPONENT_CODE = 'LAMINATION'
    NAME = 'LaminationTime'

    # =================== Lamination Front ===================
    def spec_key_front
      @spec_key_front ||= SpecKey.find_by(code: 'lamination').id
    end

    def lamination_front_ratecard
      @lamination_front_ratecard ||= begin
        spec_value = SpecValue.find(@product._spec[spec_key_front.to_s])
        PartnerRatecard.joins(:component).find_by(partner_id: @partner.id, version: 'ALL', 'components.id': spec_value.component.id)
      end
    end

    def lamination_front_tier
      @lamination_front_tier ||= lamination_front_ratecard.partner_ratecard_tiers.by_quantity(@total_material_quantity)
    end

    def lamination_front_speed
      @lamination_front_speed ||= lamination_front_tier.production_time
    end

    def lamination_front_time
      # check if available on product spec
      return 0 if @product._spec[spec_key_front.to_s].blank?

      (@total_material_quantity / lamination_front_speed.to_f).ceil
    end

    # =================== Lamination Back ===================
    def spec_key_back
      @spec_key_back ||= SpecKey.find_by(code: 'lamination_b').id
    end

    def lamination_back_ratecard
      @lamination_back_ratecard ||= begin
        spec_value = SpecValue.find(@product._spec[spec_key_back.to_s])
        PartnerRatecard.joins(:component).find_by(partner_id: @partner.id, version: 'ALL', 'components.id': spec_value.component.id)
      end
    end

    def lamination_back_tier
      @lamination_back_tier ||= lamination_front_ratecard.partner_ratecard_tiers.by_quantity(@total_material_quantity)
    end

    def lamination_back_speed
      @lamination_back_speed ||= lamination_back_tier.production_time
    end

    def lamination_back_time
      # check if available on product spec
      return 0 if @product._spec[spec_key_back.to_s].blank?

      (@total_material_quantity / lamination_back_speed).ceil
    end

    # Calculate total Calculation
    def time
      @time ||= lamination_front_time + lamination_back_time
    end

    def set_description
      product_data["#{self.class::NAME.downcase}_description"] = <<~DESC
        Jumlah Material : <b>#{ number @total_material_quantity }</b>
        Kecepatan Laminasi Depan : <b>#{ number lamination_front_tier.production_time } lembar/jam</b>
        Kecepatan Laminasi Belakang : <b>#{ number lamination_back_tier.production_time } lembar/jam</b>

        Estimasi Waktu Laminasi Depan (Total Material / Kecepatan Laminasi Depan) :
        #{ number @total_material_quantity } / #{ number lamination_front_tier.production_time } = <b>#{ number_decimal lamination_front_time }</b>
        Estimasi Waktu Laminasi Belakang (Total Material / Kecepatan Laminasi Belakang) :
        #{ number @total_material_quantity } / #{ number lamination_back_tier.production_time } = <b>#{ number_decimal lamination_back_time }</b>

        </br>
        Perhitungan :
        Waktu Laminasi Depan + Waktu Laminasi Belakang
        <b>#{ number_decimal lamination_front_time } + #{ number_decimal lamination_back_time }</b>
      DESC
    end

    def perform
      is_none = @product&.spec[:lamination]&.to_s&.upcase&.casecmp('NONE')&.zero?
      return 0 if is_none

      if product_data.blank?
        @product.prices.reject! {|p| p[:partner] == @partner && p[:machine] == @machine && p[:paper] == @paper }
        @errors << "Gagal menghitung Ratecard waktu Lamination. Mohon isi terlebih dahulu data yang dibutuhkan"
        return 0
      end

      if (@product._spec[spec_key_front.to_s].present? && (lamination_front_ratecard.blank? || lamination_front_speed.blank? || lamination_front_speed.zero?)) || (@product._spec[spec_key_back.to_s].present? && (lamination_back_ratecard.blank? || lamination_back_speed.blank? || lamination_back_speed.zero?))
        @product.prices.reject! {|p| p[:partner] == @partner && p[:machine] == @machine && p[:paper] == @paper }
        @errors << "Gagal menghitung Ratecard waktu Lamination. Mohon isi terlebih dahulu data yang dibutuhkan"
        return 0
      end

      set_description

      time_name = "#{self.class::NAME.downcase}_time".to_sym
      product_data[time_name] = time

      return time
    end

  end

end
