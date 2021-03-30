# == Schema Information
#
# Table name: order_shippings
#
#  id                           :bigint           not null, primary key
#  order_id                     :bigint
#  courier                      :string
#  shipping_speed               :integer
#  booking_code                 :string
#  awb                          :string
#  properties                   :jsonb
#  created_at                   :datetime         not null
#  updated_at                   :datetime         not null
#  status                       :string
#  order_shipping_base_id       :integer
#  shipping_fee                 :integer          default(0)
#  service_name                 :string
#  logistic_shipping_courier_id :bigint
#  service_code                 :string
#  shipping_quotation_id        :integer
#  organization_address_id      :bigint
#  deleted_at                   :datetime
#  partner_id                   :bigint
#

module Prism
  class OrderShipping < PrismModel
    acts_as_paranoid

    belongs_to :order

    has_many :order_shipping_items
    has_many :order_items, through: :order_shipping_items
  end
end
