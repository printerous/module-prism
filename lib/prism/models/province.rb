# == Schema Information
#
# Table name: provinces
#
#  id          :bigint(8)        not null, primary key
#  country_id  :bigint(8)
#  abbr        :string
#  name        :string
#  tags        :string
#  deleted_at  :datetime
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  integration :jsonb
#

module Prism
  class Province < PrismModel
  end
end
