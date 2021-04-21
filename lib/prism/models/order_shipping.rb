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
    belongs_to :organization_address, optional: true

    has_many :order_shipping_items, dependent: :destroy
    has_many :main_shipping_items, -> { joins(:order_item).where('order_items.parent_id': nil) }, class_name: 'Prism::OrderShippingItem'
    has_many :order_items, through: :order_shipping_items

    def ensure_main_shipping_items
      return main_shipping_items if main_shipping_items.present?

      order_shipping_items.select{|osi| osi.order_item.parent_id.blank? }
    end

    def ensure_organization_address
      return organization_address if organization_address.present?

      ensure_main_shipping_items&.first&.order_item&.shipping_address
    end
  end
end
