# frozen_string_literal: true

module Prism
  class OrderWebsiteTimelineOfficer
    attr_reader :order_item, :status, :time

    def initialize(order_item, status: :created, time: Time.zone.now)
      @order_item = order_item
      @status     = status
      @time       = time
    end

    def perform
      timeline = order_item.order_website_timelines.find_or_initialize_by(status: status)
      timeline.title       = logs["#{status}_log"]
      timeline.description = logs["#{status}_sub_log"]
      timeline.time        = time
      timeline.save!
    end

    def logs
      locale    = I18n.locale.to_s
      file_path = Rails.root.join("vendor/prism/lib/prism/locale/#{locale}.yml")
      yml = YAML.load(File.read(file_path)).with_indifferent_access
      yml[locale]['order_history']['logs']
    end
  end
end
