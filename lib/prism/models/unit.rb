# frozen_string_literal: true

module Prism
  class Unit < PrismModel
    def self.options
      all.order(:name).collect { |o| [o.name, o.code] }
  end

    def self.budget_options
      all.order(:name).collect { |o| ["per #{o.name}", o.code] }
    end
  end
end
