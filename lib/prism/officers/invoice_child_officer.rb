module Prism
  class InvoiceChildOfficer
    attr_reader :invoice_main, :order, :errors

    def initialize(invoice_main, order)
      @invoice_main  = invoice_main
      @order    = order
      @slug     = SecureRandom.hex.slice(0, 4).upcase
      @errors   = ''
    end

    def perform
      # create settlement
      invoice_settlement = invoice_settlement(@invoice_main)
      # create proforma if needed
      # invoice_proforma(invoice) unless term_proforma.blank?
      invoice_settlement
    end

    private

    # def term_of_payments
    #   @term_of_payments ||= begin
    #     if order.order_terms.blank?
    #       Prism::TermGenerator.new(order).perform
    #       @order = order.reload
    #     end

    #     @order.order_terms
    #   end
    # end

    # def top_type
    #   @top_type ||= order.order_terms[0][:calculation]
    # end

    def term_settlement(invoice)
      # get term of payments
      @term_settlement ||= begin
        # top_settlement = term_of_payments.size > 1 ? term_of_payments.last : term_of_payments.first
        {
          term: 'CIA',
          value: 100,
          days: 1,
          status: invoice.status,
          price: invoice.shipping_fee + invoice.subtotal
        }

        # create_term(top_proforma)
      end
    end

    # def term_proforma
    #   @term_proforma ||= begin
    #     top_proforma = term_of_payments.size > 1 ? term_of_payments.first : nil
    #     return {} if top_proforma.blank?

    #     create_term(top_proforma)
    #   end
    # end

    def invoice_settlement(invoice)
      @invoice_settlement = create_invoice_child('InvoiceSettlement', invoice)
    end

    # def invoice_proforma(invoice)
    #   @invoice_proforma ||= create_invoice_child('InvoiceProforma', invoice)
    # end

    def create_invoice_child(type, invoice)
      # terms = type == 'InvoiceSettlement' ? term_settlement : term_proforma
      terms = term_settlement(invoice)
      return nil if terms.blank?

      invoice_number = invoice.number
      # invoice_number = "#{invoice_number}/D" if type == 'InvoiceProforma'

      due_date     = nil
      invoice_date = nil
      if terms[:status] == 'waiting_payment'
        invoice_date = Time.now
        due_date     = DateTime.now + terms[:days].days
      end
      
      invoice_child = "Prism::#{type}".constantize.find_or_initialize_by(parent_id: invoice.id)
      invoice_child.parent_id          = invoice.id
      invoice_child.number             = invoice_number
      invoice_child.billing_address_id = invoice.billing_address_id
      invoice_child.billing            = invoice.billing
      invoice_child.tax_template       = invoice.tax_template
      invoice_child.tax_policy         = invoice.tax_policy
      invoice_child.term               = {}
      invoice_child.invoice_date       = invoice_date
      invoice_child.due_date           = due_date
      invoice_child.status             = terms[:status]
      invoice_child.integration        = [{ id: order.id, type: 'Prism::Order' }]
      invoice_child.top_terms          = terms
      invoice_child.data               = { active: true }
      invoice_child.shipping_fee       = invoice.shipping_fee
      invoice_child.subtotal           = invoice.subtotal
      invoice_child.price              = invoice.shipping_fee + invoice.subtotal
      invoice_child.grand_total        = invoice.shipping_fee + invoice.subtotal
      invoice_child.save

      invoice_child
    end

    # def create_term(order_term)
    #   return {} if order_term.blank?

    #   status = order_term.name == 'CIA' ? 'submitted' : 'draft'
    #   value  = order_term.value.to_f
    #   price  = top_type == 'percentage' ? value * order.grand_total / 100 : value

    #   {
    #     id: order_term.term_id,
    #     term: order_term.name,
    #     value: value,
    #     days: order_term.baseline_due,
    #     status: status,
    #     price: price
    #   }
    # end
  end
end