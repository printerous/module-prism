# frozen_string_literal: true

# == Schema Information
#
# Table name: order_shipping_items
#
#  id                :bigint(8)        not null, primary key
#  order_shipping_id :bigint(8)
#  order_item_id     :bigint(8)
#  product_id        :integer
#  weight            :decimal(12, 2)
#  volume            :decimal(12, 2)
#  height            :decimal(12, 2)
#  width             :decimal(12, 2)
#  length            :decimal(12, 2)
#  created_at        :datetime
#  updated_at        :datetime
#  deleted_at        :datetime
#

module Prism
  class OrderShippingItem < PrismModel
    acts_as_paranoid

    belongs_to :order_shipping
    belongs_to :order_item
  end
end
