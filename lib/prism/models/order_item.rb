# == Schema Information
#
# Table name: order_items
#
#  id                     :bigint(8)        not null, primary key
#  order_id               :bigint(8)
#  type                   :string
#  number                 :string
#  title                  :string
#  product_type_id        :bigint(8)
#  shipping_address_id    :integer
#  shipping               :jsonb
#  shipping_courier_id    :integer
#  spec                   :jsonb
#  file_preview           :jsonb
#  file_proof             :string
#  file_artwork           :string
#  quantity               :float            default(0.0)
#  unit                   :string
#  price                  :decimal(12, 3)   default(0.0)
#  discount               :decimal(12, 2)   default(0.0)
#  tax_policy             :integer
#  tax                    :decimal(12, 2)   default(0.0)
#  shipping_fee           :decimal(12, 2)   default(0.0)
#  subtotal               :decimal(12, 2)   default(0.0)
#  grand_total            :decimal(12, 2)   default(0.0)
#  finish_time            :datetime
#  delivery_time          :datetime
#  data                   :jsonb
#  config                 :jsonb
#  status                 :integer
#  deleted_at             :datetime
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  integration            :jsonb
#  organization_asset_id  :integer          default(0)
#  file_reference         :string
#  billing_address_id     :integer
#  billing                :jsonb
#  original_files         :jsonb
#  device_source          :string
#  user_agent             :string
#  product_id             :integer
#  flag                   :string
#  cuanki_product_type_id :integer
#  pic_id                 :integer
#  pic_support_id         :integer
#

module Prism
  class OrderItem < PrismModel
    include ActionView::Helpers::NumberHelper
    acts_as_paranoid

    belongs_to :order, -> { with_deleted }
    belongs_to :product_type, -> { with_deleted }
    belongs_to :product, class_name: 'Cuanki::Product', optional: true

    belongs_to :parent, class_name: 'Prism::OrderItem', foreign_key: :parent_id
    has_many   :item_groups, class_name: 'Prism::OrderItem', foreign_key: :parent_id, dependent: :destroy

    belongs_to :shipping_address, -> { with_deleted }, class_name: 'Prism::OrganizationAddress', foreign_key: :shipping_address_id, optional: true
    belongs_to :billing_address, -> { with_deleted }, class_name: 'Prism::OrganizationAddress', foreign_key: :billing_address_id, optional: true

    has_many :order_website_statuses
    has_one  :order_website_status, -> { where.not(time: nil).order time: :desc }
    has_many :order_website_statuses_active, -> { where.not(time: nil).order time: :asc }, class_name: 'OrderWebsiteStatus'

    has_many :order_website_timelines
    has_many :children, class_name: 'Prism::OrderItem', foreign_key: :parent_id

    has_many :order_design_approvals, class_name: 'Prism::OrderDesignApproval', dependent: :destroy
    has_many :order_item_prices, dependent: :destroy

    has_many :order_shipping_items, dependent: :destroy
    has_one  :order_shipping_item, -> { order(id: :desc) }

    has_one  :cart_item_conversion, -> { order(id: :desc) }, class_name: 'Stark::CartItemConversion'

    has_one :invoice_item
    has_one :invoice, through: :invoice_item
    has_one :invoice_main, class_name: 'InvoiceMain', through: :invoice_item

    enum tax_policy:  %i[notax tax_inclusive tax_exclusive]
    enum status:      %i[draft submitted completed cancelled]

    def self.generate_number(order_number:, counter: 1)
      number = format('%<order_number>s-%<counter>d', order_number: order_number, counter: counter)
      number.upcase!
      with_deleted.find_by(number: number) ? generate_number(order_number: order_number, counter: counter + 1) : number
    end

    def previews
      [file_preview].flatten.reject { |item| item.blank? || item == "null" }
    end

    def preview
      return previews.first if previews.present?

      'placeholder-nopreview.png'
    end

    def cart_item
      cart_item_conversion&.cart_item
    end

    def user_spec
      cart_item&.spec || spec
    end

    def quantity_label
      @quantity_label ||= data['quantity_label'] || generate_label!
    end

    def generate_label!
      formatted_qty = number_with_precision(quantity, delimiter: '.', separator: ',', precision: 0)
      data['quantity_label'] = [formatted_qty, unit].join(' ')
      data['quantity_label'] = [formatted_qty, combined_diffs].join(' x ') if combined?

      update_columns data: data
      data['quantity_label']
    end

    def combined_diffs
      values = spec.values

      if parent.present?
        other_values = parent.spec.values
      else
        other_values = item_groups.first.spec.values
      end

      diffs = values - other_values
      diffs.join(', ')
    end

    def combined_quantity
      return quantity unless combined?

      if parent.blank?
        quantity + item_groups.sum(:quantity)
      else
        parent.quantity + parent.item_groups.sum(:quantity)
      end
    end

    def combined?
      item_groups.present? || parent.present?
    end

    def working_day
      item_prices = order_item_prices
      item_prices.select { |ip| %w[waiting sent approved].include?(ip.status) }.first&.working_day ||
      item_prices.first.working_day
    end

    def shipping_speed
      order_shipping_item.order_shipping.shipping_speed
    end
  end
end
