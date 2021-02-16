# == Schema Information
#
# Table name: product_types
#
#  id          :bigint(8)        not null, primary key
#  code        :string
#  name        :string
#  tags        :string
#  deleted_at  :datetime
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  active_at   :datetime
#  inactive_at :datetime
#  spec_set_id :bigint(8)
#  integration :jsonb
#

module Prism
  class ProductType < PrismModel
    acts_as_paranoid
  end
end
