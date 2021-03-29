# frozen_string_literal: true

module Prism
  class OrderItemDesignApprovalOfficer
    attr_reader :order_item, :options

    def initialize(order_item, options)
      @order_item = order_item
      @options    = options.with_indifferent_access
    end

    def perform
      return true if design_approval.persisted?

      design_approval.type   = 'OrderDesignApproval'
      design_approval.status = nil
      design_approval.data   = options
      design_approval.save!
    end

    def design_approval
      @design_approval ||= order_item.order_design_approvals.first ||
                           order_item.order_design_approvals.new
    end
  end
end
