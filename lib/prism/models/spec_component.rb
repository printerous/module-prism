# frozen_string_literal: true

module Prism
  class SpecComponent < PrismModel
    acts_as_paranoid

    belongs_to :component
    belongs_to :spec_value

    scope :by_rules, ->(rules) {
      return where(nil) if rules.blank?
      where("spec_components.rules IS NOT NULL AND spec_components.rules @> ?", rules.to_json)
    }
  end
end
