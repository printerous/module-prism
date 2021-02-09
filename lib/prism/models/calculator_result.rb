# frozen_string_literal: true

module Prism
  class CalculatorResult < PrismModel
    acts_as_paranoid

    belongs_to :partner
  end
end
