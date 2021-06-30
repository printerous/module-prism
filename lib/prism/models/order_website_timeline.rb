# == Schema Information
#
# Table name: order_website_timelines
#
#  id            :bigint(8)        not null, primary key
#  order_item_id :bigint(8)
#  status        :string
#  title         :string
#  description   :string
#  time          :datetime
#  deleted_at    :datetime
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#

module Prism
  class OrderWebsiteTimeline < PrismModel
    acts_as_paranoid

    STATUS = %w[created payment_expired waiting_payment payment_accepted on_production on_shipping delivered payment_cancelled].freeze

    belongs_to :order_item

    STATUS.each do |s|
      define_method [s, '?'].join do
        status == s.to_s
      end

      define_method [s, '!'].join do
        update status: s
      end
    end

    def estimated_time
      return time if time.present?

      return estimated_finish_time if on_production?

      return estimated_delivery_time if on_shipping?
    end

    def estimated_finish_time
      return time if time.present?

      order_item.finish_time
    end

    def estimated_delivery_time
      return time if time.present?

      order_item.delivery_time
    end
  end
end
