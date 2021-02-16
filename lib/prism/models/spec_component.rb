# frozen_string_literal: true

# == Schema Information
#
# Table name: spec_components
#
#  id            :bigint(8)        not null, primary key
#  spec_value_id :bigint(8)
#  component_id  :bigint(8)
#  rules         :jsonb
#  deleted_at    :datetime
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  printing_type :string
#


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
