# frozen_string_literal: true

module Prism
  class OrderItemTimeRecalculationOfficer
    attr_reader :order_item, :options

    def initialize(order_item, options = {})
      @order_item = order_item
      @options    = options.with_indifferent_access
    end

    def perform
      finish_time   = BusinessDay::Officer.new(start_date, working_day).calculate.to_datetime.in_time_zone.change(hour: 15)
      delivery_time = BusinessDay::Officer.new(finish_time, shipping_speed).calculate.to_datetime.in_time_zone.change(hour: 15)

      order_item.finish_time   = finish_time
      order_item.delivery_time = delivery_time
      order_item.save!
    end

    private

    def start_date
      now = Time.zone.now
      @start_date ||= if now.hour > 12 || now.on_weekend?
                        BusinessDay::Officer.new(now.to_date, 1).calculate
                      else
                        now.to_date
                      end
    end

    def working_day
      options[:working_day] || order_item.working_day
    end

    def shipping_speed
      options[:shipping_speed] || order_item.shipping_speed
    end
  end
end
