# frozen_string_literal: true

# == Schema Information
#
# Table name: calculator_results
#
#  id          :bigint(8)        not null, primary key
#  partner_id  :bigint(8)
#  calculator  :string
#  spec        :jsonb
#  spec_id     :jsonb
#  quantity    :float            default(0.0)
#  price       :decimal(12, 2)   default(0.0)
#  working_day :float            default(0.0)
#  deleted_at  :datetime
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  data        :jsonb
#


module Prism
  class CalculatorResult < PrismModel
    VARIANT_METHOD = {
      'Calculator::DigitalCalculator' => 'digital_calculator',
      'Calculator::LargeFormatCalculator' => 'large_format_calculator',
      'Calculator::DigitalEcoCalculator' => 'digital_eco_calculator',
      'Calculator::OffsetCalculator' => 'offset_calculator',
      'Calculator::CorrugatedCalculator' => 'corrugated_calculator'
    }.freeze

    acts_as_paranoid

    belongs_to :partner
  end
end
