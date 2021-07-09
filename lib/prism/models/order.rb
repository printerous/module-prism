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
#  shipping_discount      :decimal(12, 2)   default(0.0)
#  checkout_id            :string
#

module Prism
  class Order < PrismModel
    include Hashid::Rails if "Hashid::Rails".safe_constantize.present?
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

    has_many :order_terms, dependent: :destroy

    has_many :cart_payments, class_name: 'Stark::CartPayment', foreign_key: :order_reference, primary_key: :number # All cart_payments include cancelled
    has_one  :cart_payment, -> { not_cancelled.order(id: :desc) }, class_name: 'Stark::CartPayment', foreign_key: :order_reference, primary_key: :number # Latest not_cancelled cart_payment

    has_one :order_reference, class_name: 'Stark::CartPayment', foreign_key: :order_reference, primary_key: :number
    has_one :cart, through: :order_reference, class_name: 'Stark::Cart'

    enum tax_policy:     %i[notax tax_inclusive tax_exclusive]
    enum status:         %i[draft submitted completed cancelled]
    enum payment_status: %i[unpaid partial paid expired cancelled], _prefix: :payment

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

    def paid?
      payment_status == 'paid'
    end

    def term_of_invoice
      payment_info['term_of_invoice']
    end

    def invoice
      # TODO: this method need revisit
      Prism::InvoiceMain.by_integration('Prism::Order', id)
    end

    def total_discount
      discount + shipping_discount
    end

    def ensure_order_shippings
      return order_shippings.reject { |os| os.order_shipping_items.blank? } if order_shippings.present? && order_shippings.any? { |os| os.order_shipping_items.present? }

      Prism::EnsureOrderShippingOfficer.new(self).perform
      order_shippings.reload
    end

    def user_payment_status
      locale    = I18n.locale.to_s

      file_path = File.join(File.dirname(__dir__), "/locale/#{locale}.yml")
      yml = YAML.safe_load(File.read(file_path)).with_indifferent_access
      yml[locale]['payment_status'][payment_status]
    end

    def feedback_url
      "#{ENV.fetch('FEEDBACK_SERVICE_URL', 'https://feedback.printerous.com')}/#{hashid}?utm_source=website&utm_medium=button&clicked=true"
    end
  end
end
