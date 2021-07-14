# frozen_string_literal: true

module Prism
  class OrderPicAssignment
    BUSINESS_LINE_OPTIONS = {
      'Moments Website' => { orders: { type: 'OrderMoment' }, order_items: { device_source: %w[mobile desktop] } },
      'Moments Apps' => { orders: { type: 'OrderMoment' }, order_items: { device_source: 'apps' } },
      'Panorama' => { orders: { type: 'OrderApiConnect', source: 'external-panorama' } },
      'Pro Account' => { orders: { type: 'OrderProAccount' } },
      'Sweet Escape' => { orders: { type: 'OrderApiConnect', source: 'external-sweetescape' } },
      'Website Business Desktop' => { orders: { type: 'OrderWebsite' }, order_items: { device_source: 'desktop' } },
      'Website Business Mobile' => { orders: { type: 'OrderWebsite' }, order_items: { device_source: 'mobile' } },
      'Inventory' => { orders: { type: 'OrderOfflineSales', category: 'inventory' } },
      'Offline Sales' => { orders: { type: 'OrderOfflineSales' } },
      'Tokopedia Connect' => { orders: { type: 'OrderApiConnect', source: 'external-tokopedia' } },
      'Internal Use' => { orders: { category: %w[internal_use internal-use] } },
      'Reprint' => { orders: { category: 'reprint' } },
      'Sample' => { orders: { category: 'sample' } },
    }.freeze

    def initialize(order_item_ids = [])
      @order_item_ids = order_item_ids
    end

    def perform
      # group by orders
      group_by_orders = order_items.group_by(&:order)
      group_by_orders.each do |order, items|
        organization_id = order.organization&.id
        sales_id = order.sales_id

        items.each do |order_item|
          mapping = business_line_mapping(order, order_item)
          next if mapping.blank?

          source = mapping.first
          puts "RESULT business_line_mapping: #{source}"

          next if source.blank?

          pic_order = Prism::OrderPicFinder.new(source, order_item).perform

          puts pic_order

          next if pic_order.blank?

          order_item.pic_id = pic_order.pic_id
          order_item.pic_support_id = pic_order.pic_support_id
          order_item.save
        end
      end
    end

    def order_items
      @order_items ||= Prism::OrderItem.eager_load(order: :organization).where(id: @order_item_ids)
    end

    def business_line_mapping(order, order_item)
      order_type     = order.type
      device_source  = order_item.device_source
      order_source   = order.source
      order_category = order.category

      puts '------------------'
      puts order_type
      puts device_source
      puts order_source
      puts order_category
      puts '------------------'


      BUSINESS_LINE_OPTIONS.detect do |source, conditions|
        results = []
        order_type_condition = conditions[:orders][:type]
        order_source_conditions = conditions[:orders][:source]
        order_category_conditions = conditions[:orders][:category]
        item_device_condition = [conditions[:order_items].try(:[], 'device_source') || []].flatten.compact

        results.push order_type == order_type_condition if order_type_condition.present?

        results.push order_source_conditions == order_source if order_source_conditions.present?

        if item_device_condition.present?
          if item_device_condition.include?(device_source)
            results.push true
          else
            results.push false
          end
        end

        results.push order_category == order_category_conditions if order_category_conditions.present?

        if results.blank?
          false
        else
          results.all? { |e| e == true }
        end
      end
    end
  end
end
