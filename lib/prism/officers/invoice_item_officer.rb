module Prism
  class InvoiceItemOfficer
    attr_reader :invoice, :order_item, :errors

    def initialize(invoice, order_item)
      @invoice    = invoice
      @order_item = order_item
      @errors     = ''
    end

    def perform
      invoice_item = invoice.invoice_items.find_or_initialize_by(order_item_id: order_item.id)
      invoice_item.title       = order_item.title
      invoice_item.quantity    = order_item.quantity
      invoice_item.unit        = order_item.unit
      invoice_item.tax_policy  = order_item.tax_policy
      invoice_item.subtotal    = order_item.subtotal
      invoice_item.grand_total = order_item.grand_total
      invoice_item.integration = [{ id: order_item.id, type: 'OrderItem' }]
      invoice_item.slug        = @slug
      invoice_item.save
    rescue StandardError => e
      ExceptionNotifier.notify_exception(e, data: { message: 'was doing something wrong', invoice_id: invoice.id, order_item_id: order_item.id })
      @errors = e.message
      false
    end
  end
end