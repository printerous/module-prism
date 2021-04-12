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
  class Invoice < PrismModel
    acts_as_paranoid

    SLA_PROCESSING = 5
    DEFAULT_DUE_DATE_DAYS = 15

    STATUSES = {
      draft: 'draft',
      submitted: 'submitted',
      completed: 'completed',
      cancelled: 'cancelled',
      processing: 'processing',
      waiting_payment: 'waiting_payment',
      void: 'void'
    }.freeze

    FILTER_STATUS = { 'Draft' => 'draft', 'Created' => 'submitted', 'Processing' => 'processing', 'Waiting for Payment' => 'waiting_payment', 'Completed' => 'completed', 'Cancelled' => 'cancelled' }.freeze

    has_many :invoice_logs
    has_many :invoice_payments

    has_many :child_invoices, class_name: 'Invoice', foreign_key: 'parent_id'
    belongs_to :invoice_parent, foreign_key: :parent_id, class_name: 'Invoice', optional: true

    has_one :invoice_settlement, class_name: 'InvoiceSettlement', foreign_key: 'parent_id'
    has_one :invoice_proforma, class_name: 'InvoiceProforma', foreign_key: 'parent_id'

    has_many :order_items, through: :invoice_items
    has_one :order, through: :order_items

    has_many :invoice_items
    has_many :order_items, through: :invoice_items
    has_many :orders, -> { distinct }, through: :invoice_items

    belongs_to :billing_address, -> { with_deleted }, class_name: 'OrganizationAddress', foreign_key: :billing_address_id

    has_one :organization, through: :billing_address
    has_one :organization_financial_detail, through: :organization

    has_many :invoice_versions

    enum tax_template: %i[hide_tax show_tax]
    enum tax_policy: %i[notax tax_inclusive tax_exclusive]

    scope :by_user_id, lambda { |user_id|
      id = [user_id].flatten.reject { |i| i.try(:empty?) }
      return where(nil) unless id.any?

      eager_load(orders: [:user])
        .where(users: { id: id })
    }

    scope :by_organization_id, lambda { |organization_id|
      organization_id = [organization_id].flatten.reject(&:blank?)
      return where(nil) if organization_id.blank?

      eager_load(:organization)
        .where(organizations: { id: organization_id })
    }

    scope :by_status, lambda { |status|
      status = [status].flatten.reject { |i| i.try(:empty?) }
      return where(nil) unless status.any?

      where(status: status)
    }

    scope :by_invoice_number, lambda { |number|
      return where(nil) if number.blank?

      where('invoices.number ILIKE ?', "%#{number}%")
    }

    scope :by_date_range, lambda { |date_from, date_to, date_column|
      return where(nil) if date_from.blank? && date_to.blank?

      date_to   = date_from if date_to.blank?
      date_from = date_to   if date_from.blank?
      where("(invoices.#{date_column} BETWEEN ? AND ?)", date_from.to_date.beginning_of_day, date_to.to_date.end_of_day)
    }

    def self.search(params = {})
      params = {} if params.blank?

      by_query(params[:query])
        .by_organization_id(params[:organization_id])
        .by_status(params[:status])
        .by_child_status(params[:child_status])
        .by_user_id(params[:user_id])
        .by_summary(params[:delay], params[:step])
        .by_ids(params[:ids])
    end

    def self.generate_number(type = 'INV')
      number = format("#{type}/%s/%s", Date.today.strftime('%y%m%d'), SecureRandom.hex.slice(0, 4).upcase)
      number.upcase!
      find_by(number: number) ? generate_number : number
    end

    def self.by_integration(model, id)
      find_by('integration @> ?', [{ id: id, type: model }].to_json)
    end

    def self.monitoring_data
      where(type: %w[InvoiceProforma InvoiceSettlement])
    end

    def base_number
      rev_index = number.index('/Rev')
      return number if rev_index.blank?

      number[0..(rev_index - 1)]
    end

    def process_complete?
      status == 'waiting_payment'
    end

    def payment_complete?
      status == 'completed'
    end

    def term_invoice
      days = term['days'] || ''
      term_type = term['term'] || ''
      term_type.to_s
    end

    def get_integration(model)
      source_id = get_integration_id(model)
      return nil if source_id.blank?

      model.to_s.constantize.with_deleted.find_by id: source_id
    end

    def get_integration_id(model)
      return nil if integration.blank?

      integration.find { |int| int['type'] == model.to_s }.try(:[], 'id')
    end

    def order
      order_id = get_integration_id('Order')
      Order.includes(:user).find(order_id)
    end

    def user
      order.user
    end

    def person
      order.person
    end

    def mail_config
      {
        subject: "Printerous Invoice #{number}",
        to: billing_address.pic_email,
        cc: person.email,
        bcc: [user.email, 'finance.ar@printerous.com'].reject(&:blank?)
      }
    end

    def term_of_payment
      term['term']
    end

    def active?
      # DEPRECATED FUNCTION, REPLACED WITH TOP
      # return true if term_of_payment == 'before_production' || term['force_proforma'] == true
      #
      # if term_of_payment == 'before_delivery'
      #   order_accepted?
      # elsif term_of_payment == 'after_order_completed'
      #   order.completed?
      # else
      #   false
      # end
      data['active']
    end

    def active!
      data['active'] = true
      save!
    end

    def inactive!
      data['active'] = false
      save!
    end

    def order_accepted?
      order_item_mass = order.order_items_mass.includes([:selected_order_item_price])
      order_item_mass.size == order_item_mass.select { |item| item.selected_order_item_price.present? }.size
    end

    def total_paid
      invoice_payments.select(&:paid?).sum(&:price)
    end

    def parent
      if parent_id.blank?
        self
      else
        invoice_main
      end
    end

    def hardcopy?
      invoice_format = organization_financial_detail.try(:invoice_format) || {}
      invoice_format['hardcopy'] == 'true'
    end

    def softcopy?
      invoice_format = organization_financial_detail.try(:invoice_format) || {}
      invoice_format['softcopy'] == 'true'
    end

    def before_delivery?
      order_items = invoice_items.map(&:order_item?)
      partner_order_items = order_items.map(&:partner_order_item).reject(&:blank?)
      return false if partner_order_items.blank?

      partner_order_item_statuses = partner_order_items.map(&:status)

      partner_order_item_statuses.all? { |item| item == 'onproduction' }
    end

    def after_completed?
      order_items = invoice_items.map(&:order_item)
      partner_order_items = order_items.map(&:partner_order_item).reject(&:blank?)
      return false if partner_order_items.blank?

      partner_order_item_statuses = partner_order_items.map(&:status)

      partner_order_item_statuses.all? { |item| item == 'finished' }
    end

    def status_date
      log = invoice_logs.where(status: status).order(id: :desc).first
      return created_at if log.blank?

      log.created_at
    end

    def upcoming_revision_number
      revision_size = invoice_versions.size
      rev = 'Rev1'
      rev = "Rev#{revision_size + 1}" if revision_size.positive?

      "#{number}/#{rev}"
    end

    def date_submitted
      data['status_change'].try(:[], 'submitted').try(:to_date) || invoice_logs.where(status: 'submitted').last.try(:created_at) || created_at
    end

    def sla_submitted
      DateTime.now.to_date - date_submitted.to_date
    end

    def date_processing
      data['status_change'].try(:[], 'processing').try(:to_date) || invoice_logs.where(status: 'processing').last.try(:created_at) || updated_at
    end

    def deadline_processing
      return date_processing + Invoice::SLA_PROCESSING.days if data['deadline_processing'].blank?

      data['deadline_processing']
    end

    def processing_duration
      DateTime.now.to_date - date_processing.to_date
    end

    def sla_processing
      deadline_processing.to_datetime - DateTime.now.beginning_of_day
    end

    def date_waiting_payment
      data['status_change'].try(:[], 'waiting_payment').try(:to_date) || invoice_logs.where(status: 'waiting_payment').last.try(:created_at) || updated_at
    end

    def new_due_date
      return due_date unless due_date.blank?

      date_waiting_payment + Invoice::DEFAULT_DUE_DATE_DAYS.days
    end

    def subtotal_price
      return tax_inclusive? ? subtotal.to_f / 1.1 : subtotal.to_f if show_tax?

      tax_inclusive? ? subtotal.to_f : subtotal.to_f * 1.1
    end

    def shipping_fee_price
      return tax_inclusive? ? shipping_fee.to_f / 1.1 : shipping_fee.to_f if show_tax?

      tax_inclusive? ? shipping_fee.to_f : shipping_fee.to_f * 1.1
    end

    def gross_total_price
      subtotal_price.to_f - discount.to_f + shipping_fee_price.to_f
    end

    def tax_price
      return 0 unless show_tax?
      return gross_total_price.to_f * 0.1 / 1.1 if tax_inclusive?
      return gross_total_price.to_f * 0.1 if tax_exclusive?

      0
    end

    def grand_total_price
      gross_total_price + tax_price
    end

    def top_name
      top_terms.try(:[], 'name') || top_terms['term']
    end

    def top_value
      top_terms.try(:[], 'value') || top_name.to_i || 1
    end

    def top_day
      top_terms.try(:[], 'days') || top_name.to_i
    end

    def cia?
      top_terms['term'] == 'CIA'
    end

    def cod?
      top_terms['term'] == 'COD'
    end

    def eom?
      top_terms['term'] == 'EOM'
    end

    private

    def update_main_status
      childs = invoice_main.invoices
      index_status = childs.map { |inv| Invoice::STATUSES.with_indifferent_access.find_index { |k, _v| k == inv.status } }

      index_status.reject!(&:nil?)
      return if index_status.blank?

      keys = Invoice::STATUSES.keys
      min_status = Invoice::STATUSES[keys[index_status.min]]

      invoice_main.status = min_status
      invoice_main.save
    end
  end
end
