# frozen_string_literal: true

# Handle old order which has no order shipping information
module Prism
  class EnsureOrderShippingOfficer
    attr_reader :order

    def initialize(order)
      @order = order
    end

    def perform
      grouped_items.map do |_group, order_items|
        order_item = order_items.first
        cart_item  = order_item.cart_item

        order_shipping = order.order_shippings.new
        order_shipping.organization_address_id = order_item.shipping_address_id
        order_shipping.courier                 = cart_item.data.try(:[], 'shipping').try(:[], 'courier')
        order_shipping.service_code            = cart_item.data.try(:[], 'shipping').try(:[], 'service')
        order_shipping.service_name            = order_shipping.service_code
        order_shipping.shipping_speed          = cart_item.data.try(:[], 'shipping_speed')
        order_shipping.shipping_fee            = order_items.map(&:shipping_fee)&.sum&.to_f
        order_shipping.status                  = order_item.status

        order_items.map do |item|
          order_shipping.order_shipping_items.new(
            order_item_id: item.id,
            product_id: item.product_id,
            weight: order_items.map{|item| item.data.try(:[], 'weight')&.to_f || 0 }&.sum&.to_f
          )
        end

        order_shipping.save!
      end.all?
    end

    def grouped_items
      @grouped_items ||= order.order_items.group_by { |item| [item.shipping_address_id, item.working_day] }
    end
  end
end
