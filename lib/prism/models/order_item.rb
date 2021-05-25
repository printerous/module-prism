# frozen_string_literal: true

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

    MONITOR_STATUS = {
      drft: 'Draft',
      dsgn: 'Need Layouter Design (DSGN)',
      fnce: 'Need Finance Approval (FNCE)',
      drej: 'Design Rejected (DREJ)',
      crpo: 'Need Create PO (CRPO)',
      papr: 'Need Partner Approval (PAPR)',
      onpr: 'On Production by Partner (ONPR)',
      pasn: 'Item sent to PRTS (PASN)',
      rcvd: 'Received by PRTS (RCVD)',
      neqc: 'Need QC (NEQC)',
      qcok: 'QC Passed. Need Packing (QCOK)',
      pckd: 'Packed. Need to Deliver (PCKD)',
      ship: 'Undershipment (SHIP)',
      arvd: 'Arrived (ARVD)',
      cplt: 'Completed (CPLT)',
      canc: 'Cancelled (CANC)'
    }.with_indifferent_access

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

    has_many :order_item_prices
    has_one  :waiting_order_item_price, -> { where(status: :waiting).where('partner_id IS NOT NULL').order(created_at: :desc) }, class_name: 'Prism::OrderItemPrice'

    has_one :order_reference_proof, -> { where(reference_type: :proof).order(id: :desc) }, class_name: 'Prism::OrderReference', foreign_key: :order_mass_id
    has_one :order_item_proof, through: :order_reference_proof, source: :order_proof

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
        item_prices.first&.working_day
    end

    def shipping_speed
      return parent.shipping_speed if order_shipping_item.blank?

      order_shipping_item.order_shipping.shipping_speed
    end

    def partner_deadline
      @partner_deadline ||= begin
        working_day = waiting_order_item_price.present? ? waiting_order_item_price.working_day.day : 0.day
        DateTime.now.change(hour: 15, min: 0, sec: 0) + working_day
      end
    end

    def cuanki_product
      Cuanki::Product.find(product_id)
    end

    def vas?
      return false if product_id.blank?

      cuanki_product_type = if cuanki_product_type_id.blank?
                              cuanki_product.product_type
                            else
                              Cuanki::ProductType.find(cuanki_product_type_id)
                            end

      return false if cuanki_product_type.blank?

      cuanki_product_type.flag == 'vas'
    end

    def bundling_b2c?
      flag.present? && flag.downcase.casecmp?('bundling-b2c')
    end

    def bundle?
      flag.present? && flag.downcase.casecmp?('bundle')
    end

    def nationwide?
      flag.present? && flag.downcase.casecmp?('nationwide')
    end

    def moments_web?
      order.type == 'OrderMoment' && %w[mobile desktop].include?(device_source)
    end

    def moments_apps?
      order.type == 'OrderMoment' && device_source == 'apps'
    end

    def panorama?
      order.type == 'OrderApiConnect' && order.source == 'external-panorama'
    end

    def pro_account?
      order.type == 'OrderProAccount'
    end

    def sweet_escape?
      order&.type == 'OrderApiConnect' && order.source == 'external-sweetescape'
    end

    def offline_sales?
      order.type == 'OrderOfflineSales'
    end

    def tokopedia?
      order&.type == 'OrderApiConnect' && order&.source == 'external-tokopedia'
    end

    def website_desktop?
      order.type == 'OrderWebsite' && (device_source == 'desktop' || device_source.nil?)
    end

    def website_mobile?
      order.type == 'OrderWebsite' && device_source == 'mobile'
    end

    def internal_use?
      order.category == 'internal-use' || order.category == 'internal_use'
    end

    def reprint?
      order.category == 'reprint'
    end

    def sample?
      order.category == 'sample'
    end

    def inventory?
      order.category == 'inventory'
    end

    def monitoring_statuses
      [data['monitoring_status']]&.flatten&.compact
    end

    def translated_unit
      unit_type = quantity.to_i > 1 ? 'plural' : 'singular'
      I18n.t("unit.#{unit_type}.#{unit.downcase}")
    end
  end
end
