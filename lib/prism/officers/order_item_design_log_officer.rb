# frozen_string_literal: true

module Prism
  class OrderItemDesignLogOfficer
    attr_reader :order_item, :cart_item, :order

    def initialize(order_item)
      @order_item = order_item
      @cart_item  = order_item.cart_item
      @order      = order_item.order
    end

    def perform
      return if cart_item.blank?

      design_log = Prism::OrderDesignLog.new
      design_log.order_item_id  = order_item.id
      design_log.title          = title
      design_log.file_reference = 'link'
      design_log.design         = order_item.file_artwork
      design_log.user_id        = order.user_id
      design_log.time           = Time.zone.now
      design_log.save!
    end

    private

    def title
      file_source = cart_item&.file_source

      if %w[link upload].include?(file_source)
        user_name = order.user&.name || 'User'
        [user_name, 'submitted file'].join(' ')
      elsif %w[template blank_editor].include?(file_source)
        'File generated from Printerous Editor'
      else
        'User files'
      end
    end
  end
end
