# frozen_string_literal: true

module Prism
  class OrderPicFinder
    attr_reader :source, :order_item, :options
    attr_reader :pic_id, :pic_support_id

    def initialize(source, order_item, args = {})
      @source     = source
      @order_item = order_item
      @options    = args&.to_h&.with_indifferent_access
    end

    def perform
      pics = PicOrder.where(source: source)

      pics = filtered_by('organization_id', pics)
      pics = filtered_by('sales_id', pics)
      pics = filtered_by('procurement_id', pics) if order_item.has_attribute?('procurement_id')

      pics.last
    end

    private

    def organization_id
      order_item&.organization&.id
    end

    def sales_id
      order_item&.order&.sales_id
    end

    def procurement_id
      order_item&.procurement_id
    end

    def filtered_by(method_name, pics)
      return pics if pics.blank?

      pics.select { |pic| pic.send(method_name) == send(method_name) || pic.send(method_name).blank? }
    end
  end
end
