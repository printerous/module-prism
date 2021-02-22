# frozen_string_literal: true

# == Schema Information
#
# Table name: partner_products
#
#  id                 :bigint           not null, primary key
#  partner_variant_id :bigint
#  product_id         :integer
#  spec_ids           :jsonb
#  deleted_at         :datetime
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#

module Prism
  class PartnerProduct < PrismModel
    acts_as_paranoid
    belongs_to :partner_variant

    scope :by_variant_id, lambda { |variant_id|
      return where(nil) if variant_id.blank?

      eager_load(:partner_variant)
        .where('partner_variants.variant_id = ?', variant_id)
    }
  end
end
