# frozen_string_literal: true

# == Schema Information
#
# Table name: invoices
#
#  id                 :bigint(8)        not null, primary key
#  type               :string
#  parent_id          :integer
#  number             :string
#  billing_address_id :integer
#  billing            :jsonb
#  price              :decimal(12, 2)
#  invoice_date       :datetime
#  status             :string
#  integration        :jsonb
#  deleted_at         :datetime
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  term               :jsonb
#  due_date           :datetime
#  tax_template       :integer
#  shipping_fee       :float
#  discount           :float
#  tax                :float
#  subtotal           :float
#  grand_total        :float
#  tax_policy         :integer
#  data               :jsonb
#  top_terms          :jsonb
#

module Prism
  class InvoiceProforma < Invoice
    belongs_to :invoice_main, foreign_key: :parent_id
    has_many :invoice_items, through: :invoice_main

    default_scope { includes(:organization_financial_detail) }

    after_save :update_main_status

    def pdf_title
      'INVOICE'
    end

    def total_paid
      invoice_main.invoice_payments.select(&:paid?).sum(&:price)
    end

    def total_price
      invoice_main.price.to_f
    end

    def current_bill
      amount = grand_total
      amount = total if amount.nil?

      return 0.0 if total_paid >= amount

      amount.to_f - total_paid.to_f
    end

    def total
      return term['value'].to_f if term['value_type'] != 'percentage'

      order.grand_total * term['value'].to_f / 100.0
    end
  end
end
