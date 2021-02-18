# == Schema Information
#
# Table name: pic_orders
#
#  id              :bigint(8)        not null, primary key
#  source          :string
#  sales_id        :integer
#  pic_id          :integer
#  pic_support_id  :integer
#  notes           :string
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  deleted_at      :datetime
#  organization_id :integer
#

module Prism
  class PicOrder < PrismModel
    acts_as_paranoid
  end
end
