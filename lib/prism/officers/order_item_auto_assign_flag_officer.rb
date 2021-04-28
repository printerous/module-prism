module Prism
  class OrderItemAutoAssignFlagOfficer
    attr_reader :order_item

    def initialize(order_item_id)
      @order_item = Prism::OrderItem.find order_item_id
    end

    def perform
      return if !valid?

      latest_price = order_item.waiting_order_item_price
      latest_price.flag = 'auto'
      latest_price.save!
    end

    def valid?
      latest_price_present? && partner_deadline_valid? && order_valid? && distribute_pro_account?
    end

    def order_valid?
      !order_proof? && !bundle? && !bundling_b2c? && !inventory? && !nationwide? && !vas? && !offline_sales? && !panorama? && !moments? && !sweet_escape?&& !internal_use?
    end

    def latest_price_present?
      latest_price = order_item.waiting_order_item_price
      latest_price.present?
    end

    def partner_deadline_valid?
      partner_deadline  = order_item.partner_deadline
      customer_deadline = order_item.delivery_time

      partner_deadline < customer_deadline
    end

    def order_proof?
      order_proof = order_item.order_item_proof
      order_proof.present?
    end

    def bundle?
      order_item.bundle?
    end

    def bundling_b2c?
      order_item.bundling_b2c?
    end

    def inventory?
      order_item.inventory?
    end

    def nationwide?
      order_item.nationwide?
    end

    def vas?
      order_item.vas?
    end

    def offline_sales?
      order_item.offline_sales?
    end

    def pro_account?
      order_item.pro_account?
    end

    def sweet_escape?
      order_item.sweet_escape?
    end

    def panorama?
      order_item.panorama?
    end

    def internal_use?
      order_item.internal_use?
    end

    def moments?
      order_item.moments_web? || order_item.moments_apps?
    end

    def flag_auto_distribute?
      order_item.data['auto_distribute_po']
    end

    def distribute_pro_account?
      return true unless pro_account?

      pro_account? && flag_auto_distribute?
    end
  end
end
