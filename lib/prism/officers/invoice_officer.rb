# frozen_string_literal: true

module Prism
  class InvoiceOfficer
    attr_reader :order, :data, :errors, :status

    def initialize(order, status = nil)
      @order  = order
      @status = status
      @slug   = SecureRandom.hex.slice(0, 4).upcase
      @errors = ''
    end

    def create
      @data = []
      group_by_billings = order.order_items.group_by(&:billing_address)
      group_by_billings.each do |billing_address, order_items|
        valid_items = order_items.select { |order_item| order_item.invoice_item.blank? }
        next if valid_items.blank?

        invoice = create_invoice(billing_address)

        valid_items.each do |order_item|
          Prism::InvoiceItemOfficer.new(invoice, order_item).perform
        end

        invoice.price        = valid_items.sum(&:subtotal)
        invoice.discount     = valid_items.sum(&:discount) + valid_items.sum(&:shipping_discount)
        invoice.shipping_fee = valid_items.sum(&:shipping_fee)
        invoice.subtotal     = valid_items.sum(&:subtotal)
        invoice.save!
        # Create Invoice Child
        invoice_child        = Prism::InvoiceChildOfficer.new(invoice, order).perform

        @data << invoice

        create_invoice_log(invoice, invoice_child)
      end

      true
    rescue StandardError => e
      ExceptionNotifier.notify_exception(e, data: { message: 'was doing something wrong', order_id: order.id })
      @errors = e.message
      false
    end

    def tax_template
      order.organization&.organization_financial_detail&.tax_template == true ? 1 : 0
    end

    private

    def create_invoice(billing_address)
      Prism::InvoiceMain.create(
        parent_id: nil,
        status: 'draft',
        number: Prism::Invoice.generate_number,
        billing_address_id: billing_address.id,
        billing: billing_address.address_json,
        tax_template: tax_template,
        tax_policy: order.tax_policy,
        term: {},
        invoice_date: nil,
        integration: [{ id: order.id, type: 'Order' }],
        data: { active: true }
      )
    end

    def create_invoice_log(invoice, invoice_child)
      Prism::InvoiceLoggerOfficer.new(invoice_child).invoice_created

      Prism::InvoiceLoggerOfficer.new(invoice_proforma(invoice)).invoice_created if invoice_proforma(invoice).present?
    end
  end
end
