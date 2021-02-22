# == Schema Information
#
# Table name: districts
#
#  id          :bigint(8)        not null, primary key
#  name        :string
#  city_id     :bigint(8)
#  deleted_at  :datetime
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  integration :jsonb
#  latitude    :float            default(0.0)
#  longitude   :float            default(0.0)
#  code        :string
#

module Prism
  class District < PrismModel
    acts_as_paranoid

    belongs_to :city
  end
end
