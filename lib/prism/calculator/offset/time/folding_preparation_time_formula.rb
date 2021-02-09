# frozen_string_literal: true

require File.dirname(__FILE__) + '/time_formula.rb'

module Prism
  class Calculator::Offset::Time::FoldingPreparationTimeFormula < Prism::Calculator::Offset::Time::TimeFormula
    COMPONENT_CODE = 'FOLDING'
    NAME = 'FoldingPreparationTime'

    def set_description
      product_data["#{self.class::NAME.downcase}_description"] = <<~DESC
        Estimasi Waktu Persiapan Folding : <b>#{time} jam</b>

      DESC
    end

    def time
      @time ||= begin
        tier = partner_ratecard.partner_ratecard_tiers.by_quantity(@total_material_quantity)
        tier.properties['material_time_waiting'].to_i + tier.properties['time_waiting'].to_i
      end
    end

    def perform
      is_none = @product&.spec[:folding]&.to_s&.upcase&.casecmp('NONE')&.zero?
      return 0 if is_none

      if product_data.blank? || partner_ratecard.blank?
        @product.prices.reject! { |p| p[:partner] == @partner && p[:machine] == @machine && p[:paper] == @paper }
        @errors << 'Ratecard waktu Persiapan Folding. Mohon isi terlebih dahulu data yang dibutuhkan'
        return 0
      end

      set_description

      time_name = "#{self.class::NAME.downcase}_time".to_sym
      product_data[time_name] = time

      time
    end
  end
end
