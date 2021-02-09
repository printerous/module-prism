module Prism
  class PartnerRatecardTier < PrismModel
    acts_as_paranoid

    belongs_to :partner_ratecard
    belongs_to :partner

    def self.by_quantity(quantity)
      tiers = order(quantity_top: :ASC)
      tiers.find {|tier|
        quantity <= tier.quantity_top.to_i || tiers.last == tier
      }
    end

    def self.by_druk_quantity(druk_quantity)
      find { |t|
        druk_quantity <= t.druk_quantity
      }
    end

    def additional
      properties['additional']
    end

    def druk_quantity
      quantity_top || 0
    end

    def props
      properties || {}
    end

  end

end
