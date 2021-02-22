# == Schema Information
#
# Table name: product_prices
#
#  id           :bigint(8)        not null, primary key
#  product_id   :bigint(8)
#  source_type  :string
#  source_id    :integer
#  partner_id   :bigint(8)
#  quantity     :float
#  unit         :string
#  price        :decimal(12, 2)
#  working_day  :integer
#  expired_at   :datetime
#  deleted_at   :datetime
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  quantity_max :float
#  weight       :integer          default(1)
#  price_tag    :string
#  references   :jsonb
#

module Prism
  class ProductPrice < PrismModel
    acts_as_paranoid

    attribute :rank

    belongs_to :product
    belongs_to :source, -> { with_deleted }, polymorphic: true, optional: true
    belongs_to :partner

    scope :active_price, lambda {
      where('expired_at IS NOT NULL AND expired_at >= ?', DateTime.now)
    }

    scope :non_active_price, lambda {
      where('expired_at IS NULL OR expired_at < ?', DateTime.now)
    }

    def self.by_inquiry_item_price(inquiry_item_price)
      where(product_id: inquiry_item_price.inquiry_item.product_id)
        .where(source_type: inquiry_item_price.source_type)
        .where(source_id: inquiry_item_price.source_id)
        .first
    end

    def self.by_references(model, id)
      where('"references" @> ?', [{ id: id, type: model }].to_json)
    end

    def source_calculator?
      source_type == 'CalculatorResult'
    end
  end
end
