module Prism
  class OrderShippingItem < PrismModel
    acts_as_paranoid
    belongs_to :order_shipping
    belongs_to :order_item
  end
end