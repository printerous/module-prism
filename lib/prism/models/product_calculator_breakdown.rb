# frozen_string_literal: true

module Prism
  class ProductCalculatorBreakdown < PrismModel
    acts_as_paranoid

    belongs_to :product_calculator
    belongs_to :relation, polymorphic: true, optional: true
    
  end
end
