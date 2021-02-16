# == Schema Information
#
# Table name: product_calculators
#
#  id         :bigint(8)        not null, primary key
#  code       :string
#  name       :string
#  formula    :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  deleted_at :datetime
#  properties :jsonb
#

module Prism
  class ProductCalculator < PrismModel
    acts_as_paranoid

    has_many :product_calculator_breakdowns
  end
end
