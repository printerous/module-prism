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
  end
end
