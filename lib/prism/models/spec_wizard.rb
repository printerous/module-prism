# == Schema Information
#
# Table name: spec_wizards
#
#  id            :bigint           not null, primary key
#  key           :string
#  deleted_at    :datetime
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  spec_value_id :bigint
#  spec_set_id   :bigint
#  option_ids    :jsonb
#  input_type    :string
#  spec_key_id   :integer
#  position      :integer          default("0")
#  properties    :jsonb
#

module Prism
  class SpecWizard < PrismModel
    acts_as_paranoid

    belongs_to :spec_key, optional: true
    belongs_to :spec_set

    def spec_values
      @spec_values ||= SpecValue.where(id: option_ids).uniq
    end
  end
end
