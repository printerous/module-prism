module Prism
  class PartnerVariant < PrismModel
    acts_as_paranoid

    belongs_to :partner_product_type

    def partner_id
      partner_product_type&.partner_id
    end
  end
end
