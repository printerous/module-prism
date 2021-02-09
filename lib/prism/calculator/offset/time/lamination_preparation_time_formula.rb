require File.dirname(__FILE__) + '/time_formula.rb'

module Prism
  class Calculator::Offset::Time::LaminationPreparationTimeFormula < Prism::Calculator::Offset::Time::TimeFormula
    # COMPONENT_CODE = 'LAMINATION'
    NAME = 'LaminationPreparationTime'

    def set_description
      product_data["#{self.class::NAME.downcase}_description"] = <<~DESC
        Estimasi Waktu Persiapan Laminasi : <b>#{ time } jam</b>

      DESC
    end

    def time
      results = []
      spec_values.each do |id|
        spec_value = SpecValue.find(id)
        ratecard = PartnerRatecard.joins(:component).find_by(partner_id: @partner.id, version: 'ALL', 'components.id': spec_value.component.id)

        if product_data.blank? || ratecard.blank?
          @product.prices.reject! {|p| p[:partner] == @partner && p[:machine] == @machine && p[:paper] == @paper }
          @errors << "Ratecard waktu Persiapan Lamination. Mohon isi terlebih dahulu data yang dibutuhkan"
          return 0
        end

        tier = ratecard.partner_ratecard_tiers.by_quantity(@total_material_quantity)
        results << tier.properties['material_time_waiting'].to_i + tier.properties['time_waiting'].to_i
      end

      results.max
    end

    def spec_values
      @spec_values ||= begin
        spec_keys = SpecKey.where(code: ['lamination', 'lamination_b']).collect(&:id)
        @product._spec.select{|k,v|
          spec_keys.include?(k.to_i)
        }.values.reject(&:blank?)
      end
    end

    def perform
      is_none = @product&.spec[:lamination]&.to_s&.upcase&.casecmp('NONE')&.zero?
      return 0 if is_none

      if product_data.blank?
        @product.prices.reject! {|p| p[:partner] == @partner && p[:machine] == @machine && p[:paper] == @paper }
        @errors << "Ratecard waktu Persiapan Laminasi. Mohon isi terlebih dahulu data yang dibutuhkan"
        return 0
      end

      set_description

      time_name = "#{self.class::NAME.downcase}_time".to_sym
      product_data[time_name] = time

      return time
    end

  end

end
