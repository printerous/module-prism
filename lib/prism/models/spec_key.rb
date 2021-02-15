# == Schema Information
#
# Table name: spec_keys
#
#  id             :bigint(8)        not null, primary key
#  code           :string
#  name           :string
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  deleted_at     :datetime
#  properties     :jsonb
#  deactivated_at :datetime
#

module Prism
  class SpecKey < PrismModel
    acts_as_paranoid

    def is_direct?
      properties['is_direct']&.to_i == 1
    end
  end
end
