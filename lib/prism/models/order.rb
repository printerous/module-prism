# == Schema Information
#
# Table name: orders
#
#  id                     :bigint(8)        not null, primary key
#  type                   :string
#  source                 :string
#  number                 :string
#  organization_member_id :bigint(8)
#  user_id                :bigint(8)
#  currency_id            :integer
#  tax_policy             :integer
#  tax                    :decimal(12, 2)
#  discount               :decimal(12, 2)
#  shipping_fee           :decimal(12, 2)   default(0.0)
#  subtotal               :decimal(12, 2)   default(0.0)
#  grand_total            :decimal(12, 2)   default(0.0)
#  status                 :integer
#  payment_status         :integer
#  payment_info           :jsonb
#  deleted_at             :datetime
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  data                   :jsonb
#  submitted_date         :datetime
#  integration            :jsonb
#  customer_po_file       :string
#  category               :string           default("sales")
#  po_number              :string
#  sales_id               :integer
#

module Prism
  class Order < PrismModel
    acts_as_paranoid

    belongs_to :user, -> { with_deleted }
    belongs_to :organization_member, -> { with_deleted }
    belongs_to :currency

    has_one :organization, through: :organization_member
    has_one :person, through: :organization_member

    has_many :order_items, dependent: :destroy
    has_many :main_order_items, -> { where(parent_id: nil) }, class_name: 'Prism::OrderItem'

    has_many :order_shippings, dependent: :destroy
    has_many :product_types, through: :order_items

    has_many :order_terms

    enum tax_policy:     %i[notax tax_inclusive tax_exclusive]
    enum status:         %i[draft submitted completed cancelled]
    enum payment_status: %i[unpaid partial paid]

    scope :by_query, lambda { |query|
      return where(nil) if query.blank?

      eager_load(:order_items, :organization, :person, :product_types)
        .where(
          'order_items.number ILIKE :query OR
          order_items.title ILIKE :query OR
          orders.number ILIKE :query OR
          organizations.name ILIKE :query OR
          people.name ILIKE :query OR
          product_types.name ILIKE :query',
          query: "%#{query}%"
        )
    }

    scope :by_website_status, lambda { |status|
      return where(nil) if status.blank?

      eager_load(order_items: [:order_website_status])
        .where(
          'order_website_statuses.status ILIKE :query',
          query: "%#{status}%"
        ).where(
          'order_website_statuses.time IN (
                      SELECT max(status.time) FROM order_website_statuses as status
                      WHERE status.time IS NOT NULL
                      GROUP BY status.order_item_id
                      )'
        )
    }

    def self.search(params)
      params = {} if params.blank?

      by_query(params[:query])
        .by_website_status(params[:status])
    end

    def self.generate_number(code:)
      number = format('%<code>s%<date>s%<random>s', code: code, date: Date.today.strftime('%y%m%d'), random: SecureRandom.hex.slice(0, 4).upcase)
      number.upcase!
      with_deleted.find_by(number: number) ? generate_number(code) : number
    end

    def cart_payment
      Stark::CartPayment.not_cancelled.order(id: :desc).find_by(order_reference: number)
    end

    def paid?
      payment_status == 'paid'
    end

    def term_of_invoice
      payment_info['term_of_invoice']
    end

    def invoice
      Prism::InvoiceMain.by_integration('Prism::Order', id)
    end

    def cart
      cart_payment&.cart
    end

    def ensure_order_shippings
      return order_shippings if order_shippings.present? && order_shippings.map(&:order_shipping_items).flatten.present?

      order_shipping = order_shippings.new
      order_items.map do |order_item|
        order_shipping.order_shipping_items.build order_item_id: order_item.id
      end

      [order_shipping]
    end
  end
end
