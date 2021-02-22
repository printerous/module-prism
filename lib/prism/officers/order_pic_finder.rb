# frozen_string_literal: true

module Prism
  class OrderPicFinder
    attr_reader :source, :organization_id, :sales_id, :options
    attr_reader :pic_id, :pic_support_id

    def initialize(source, organization_id, sales_id, args = {})
      @source          = source
      @organization_id = organization_id
      @sales_id        = sales_id
      @options         = args&.to_h&.with_indifferent_access
      @pic_id          = nil
      @pic_support_id  = nil
    end

    def perform
      # find by source
      pics = Prism::PicOrder.where(source: source)

      pics = pics.where(organization_id: organization_id) if pics.size > 1

      pics = pics.where(sales_id: sales_id) if pics.blank?

      if pics.blank?
        pics = Prism::PicOrder.where(source: source)
                              .where(organization_id: nil)
                              .where(sales_id.blank?)
      end

      pics.first
    end
  end
end
