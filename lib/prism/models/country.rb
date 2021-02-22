# == Schema Information
#
# Table name: countries
#
#  id          :bigint(8)        not null, primary key
#  abbr        :string
#  name        :string
#  deleted_at  :datetime
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  integration :jsonb
#

module Prism
  class Country < PrismModel
    acts_as_paranoid

    has_many :provinces
  end
end
