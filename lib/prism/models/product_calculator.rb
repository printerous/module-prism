module Prism
  class ProductCalculator < PrismModel
    acts_as_paranoid

    has_many :product_calculator_breakdowns
  end
end
