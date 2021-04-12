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
  class InvoiceMain < Invoice
    has_many :invoices, class_name: 'Invoice', foreign_key: :parent_id
    has_many :invoice_proformas, -> { where type: 'InvoiceProforma' }, class_name: 'InvoiceProforma', foreign_key: :parent_id
    has_many :invoice_settlements, -> { where type: 'InvoiceSettlement' }, class_name: 'InvoiceSettlement', foreign_key: :parent_id
    has_many :invoice_childs, -> { where.not(status: 'void').order(type: :asc) }, class_name: 'Invoice', foreign_key: :parent_id

    has_many :invoice_items, foreign_key: :invoice_id
    has_many :order_items, through: :invoice_items
    has_many :orders, -> { distinct }, through: :invoice_items
    has_many :users, through: :invoice_items
    has_many :people, through: :invoice_items, source: :person

    has_one :invoice_proforma, -> { where(type: 'InvoiceProforma').where.not(status: 'void') }, class_name: 'InvoiceProforma', foreign_key: :parent_id
    has_one :invoice_settlement, -> { where(type: 'InvoiceSettlement').where.not(status: 'void') }, class_name: 'InvoiceSettlement', foreign_key: :parent_id

    scope :outstanding, -> { joins(:orders).where(status: 'completed').where('orders.status = ?', Order.statuses[:completed]).distinct }
    scope :not_proacc, -> { joins(:orders).where.not('orders.number ILIKE :query', query: 'PA%') }
    # scope :not_panorama, -> { joins(:orders).where.not('orders.number ILIKE :query', query: 'PCPM%').where.not('orders.number ILIKE :query', query: 'PM%') }
    scope :pro_account, -> { eager_load(:orders).where(orders: { type: 'OrderProAccount' }) }

    scope :by_query, lambda { |query|
      return where(nil) if query.blank?

      query.upcase!

      orders = Order.where('number ILIKE :query',
                          query: "%#{query}%")

      order_items = if orders.present?
                      orders.map(&:order_items).flatten
                    else
                      OrderItem.where('number ILIKE :query',
                                      query: "%#{query}%")
                    end

      if order_items.blank?
        return where('invoices.number ILIKE :query',
                    query: "%#{query}%").distinct
      end

      order_item_ids = order_items.map(&:id)

      by_order_item_ids(order_item_ids)
    }

    scope :by_order_item_ids, lambda { |order_item_ids|
      return where(nil) if order_item_ids.blank?

      joins(:invoice_items)
        .where('invoice_items.order_item_id IN (?)', order_item_ids)
    }

    scope :by_child_status, lambda { |status|
      status = [status].flatten.reject { |i| i.try(:empty?) }
      return where(nil) unless status.any?

      joins(:invoice_childs)
        .where('invoice_childs_invoices.status': status)
    }

    scope :by_summary, lambda { |delay, steps|
      return where(nil) if steps.blank? || delay.blank?

      now = Time.zone.now

      scoped = joins(:invoice_childs)
              .where('invoice_childs_invoices.status': steps)
              .where("invoice_childs_invoices.data ->> 'active' = 'true'")

      # submitted

      if steps == 'submitted' && delay == 'late'
        scoped = scoped.where("'#{DateTime.now.to_date}'::DATE - (invoice_childs_invoices.data -> 'status_change' ->> 'submitted')::DATE > 0 ")
      end

      if steps == 'submitted' && delay == 'today'
        scoped = scoped.where("'#{DateTime.now.to_date}'::DATE - (invoice_childs_invoices.data -> 'status_change' ->> 'submitted')::DATE = 0 ")
      end

      # processing

      if steps == 'processing' && delay == 'late'
        scoped = scoped.where("'#{DateTime.now.to_date}'::DATE - (invoice_childs_invoices.data -> 'status_change' ->> 'processing')::DATE > 5 ")
      end

      if steps == 'processing' && delay == 'today'
        scoped = scoped.where("'#{DateTime.now.to_date}'::DATE - (invoice_childs_invoices.data -> 'status_change' ->> 'processing')::DATE = 5 ")
      end

      if steps == 'processing' && delay == 'nextday'
        scoped = scoped.where("'#{DateTime.now.to_date}'::DATE - (invoice_childs_invoices.data ->> 'deadline_processing')::DATE < 0 ")
      end

      # waiting payment
      if steps == 'waiting_payment' && delay == 'late'
        scoped = scoped.where('invoice_childs_invoices.due_date < ?', now.beginning_of_day)
      end

      if steps == 'waiting_payment' && delay == 'today'
        scoped = scoped.where('invoice_childs_invoices.due_date BETWEEN ? AND ?', now.beginning_of_day, now.end_of_day)
      end

      if steps == 'waiting_payment' && delay == 'nextday'
        deadline  = 2
        deadline += 1 if now.hour >= 15
        date = now + deadline.days

        scoped = scoped.where('invoice_childs_invoices.due_date < ?', date.beginning_of_day)
                      .where('invoice_childs_invoices.due_date > ?', now.end_of_day)
      end

      scoped
    }

    scope :by_organization_member, lambda { |organization_member_id|
      return where(nil) if organization_member_id.blank?

      where(orders: { organization_member_id: organization_member_id })
    }

    scope :by_payment_status, lambda { |status|
      return where(nil) if status.blank?

      where(orders: { payment_status: Order.payment_statuses[status] })
    }

    scope :by_ids, lambda { |ids|
      return where(nil) if ids.blank?

      where(id: ids)
    }

    def self.search_pro(params = {})
      params = {} if params.blank?

      by_invoice_number(params[:query])
        .by_organization_id(params[:organization_id])
        .by_organization_member(params[:organization_member_id])
        .by_date_range(params[:start_date], params[:end_date], (params[:date_column] || 'created_at'))
        .by_payment_status(params[:status])
    end

    def active_invoice_childs
      invoice_childs.select(&:active?)
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

    def organization
      order.try(:organization)
    end

    def active_invoice_settlement
      invoice_settlements.where.not(status: %w[void cancelled completed]).last
    end

    def active_invoices
      invoices.where.not(status: %w[void cancelled completed])
    end

    def pdf_title
      'INVOICE'
    end

    def total_paid
      invoice_payments.select(&:paid?).sum(&:price)
    end

    def total_price
      price
    end

    def invoice_main
      self
    end

    def coming
      @coming ||= begin
        deadline  = 2
        deadline += 1 if now.hour >= 15

        now + deadline.days
      end
    end
  end
end
