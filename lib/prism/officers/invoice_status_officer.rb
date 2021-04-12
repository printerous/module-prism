# frozen_string_literal: true

module Prism
  class InvoiceStatusOfficer
    attr_reader :invoice, :params, :notes, :new_status, :data, :current_user, :errors

    def initialize(invoice, params, current_user)
      @params       = params
      @invoice      = invoice
      @new_status   = params[:status]
      @notes        = params[:notes]
      @current_user = current_user
      @data         = {}
      @errors       = nil
    end

    def perform
      invoice.status = new_status
      changes        = invoice.changes

      if new_status.blank?
        @errors = "Cannot Update with empty status: #{new_status}"
        raise ActiveRecord::Rollback
      end

      if changes.blank?
        @errors = "Cannot Update with no status: #{new_status}"
        raise ActiveRecord::Rollback
      end

      invoice.save!

      # @data[:field_changes] = changes
      # log_change(invoice)
      update_invoice_main_status

      true
    rescue StandardError => e
      @errors = e.message
      false
    end

    # def log_change(invoice)
    #   @data[:notes]  = notes
    #   officer       = Invoice::LoggerOfficer.new(invoice, data, current_user)
    #   officer.invoice_updated
    # end

    # Update main invoice to complete if all childs is completed
    def update_invoice_main_status
      statuses = invoice.reload.invoice_main.invoice_childs.map(&:status).uniq
      return unless statuses.size == 1 && statuses[0] == 'completed'

      invoice.invoice_main.update status: 'completed'
    end
  end
end