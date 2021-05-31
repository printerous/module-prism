# frozen_string_literal: true

module Prism
  class OrderWebsiteStatusOfficer
    attr_reader :order_item, :status

    # accepted paid on_production on_shipping delivered cancelled expired
    def initialize(order_item, status: :accepted)
      @order_item = order_item
      @status     = status
    end

    def perform
      Prism::OrderWebsiteStatus::STATUS.map do |website_status|
        time = nil
        time = Time.zone.now if status.to_s == website_status.to_s

        item_status = order_item.order_website_statuses.find_or_initialize_by(status: website_status)
        next if item_status.time.present?

        item_status.time        = time if item_status.time.blank?
        item_status.is_complete = time.present?
        item_status.save!
      end
    end
  end
end
