module Prism
  class InvoicePaymentOfficer
    attr_reader :invoice, :params, :errors

    def initialize(invoice, params)
      @invoice = invoice
      @params  = params
    end

    def perform
      invoice_main = invoice.invoice_main
      return if invoice_main.invoice_payments.present?

      invoice_main.invoice_payments.create(
        user_id: params[:user_id],
        payment_date: params[:payment_date],
        price: params[:grand_total],
        status: :paid
      )
    rescue StandardError => e
      ExceptionNotifier.notify_exception(e, data: { message: 'was doing something wrong', invoice_id: invoice&.id, params: params })
      @errors = e.message
      false
    end
  end
end