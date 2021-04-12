# frozen_string_literal: true

# == Schema Information
#
# Table name: invoice_items
#
#  id            :bigint(8)        not null, primary key
#  invoice_id    :bigint(8)
#  order_item_id :bigint(8)
#  title         :string
#  quantity      :integer
#  unit          :string
#  discount      :decimal(12, 2)
#  tax           :decimal(12, 2)
#  tax_policy    :integer
#  shipping_fee  :decimal(12, 2)
#  subtotal      :decimal(12, 2)
#  grand_total   :decimal(12, 2)
#  integration   :jsonb
#  slug          :string
#  deleted_at    :datetime
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#
module Prism
  class InvoiceItem < PrismModel
    acts_as_paranoid

    belongs_to  :invoice
    belongs_to  :order_item
    belongs_to  :invoice_main, -> { where type: 'InvoiceMain' }, class_name: 'InvoiceMain', foreign_key: :invoice_id

    has_one     :order, through: :order_item
    has_one     :user, through: :order_item
    has_one     :person, through: :order

    def get_integration(model)
      source_id = get_integration_id(model)
      return nil if source_id.blank?

      model.to_s.constantize.with_deleted.find_by id: source_id
    end

    def get_integration_id(model)
      return nil if integration.blank?

      integration.find { |int| int['type'] == model.to_s }.try(:[], 'id')
    end

    def subtotal_with_tax
      subtotal.to_f + (0.1 * subtotal.to_f)
    rescue StandardError
      subtotal.to_f
    end

    def price
      # return order_item.price.to_f if order_item.price.to_s.split('.').last.size < 3

      order_item.price
    end

    def price_with_tax
      price + (0.1 * price)
    rescue StandardError
      price
    end
  end
end