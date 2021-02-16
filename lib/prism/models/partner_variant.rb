# == Schema Information
#
# Table name: partner_variants
#
#  id                      :bigint(8)        not null, primary key
#  partner_product_type_id :bigint(8)
#  variant_id              :integer
#  spec_ids                :jsonb
#  deleted_at              :datetime
#  created_at              :datetime         not null
#  updated_at              :datetime         not null
#  benchmark               :boolean          default(FALSE)
#  cogs_method             :jsonb
#  latest_updated_by       :integer
#  latest_updated_date     :datetime
#  priority                :boolean          default(FALSE)
#

module Prism
  class PartnerVariant < PrismModel
    acts_as_paranoid

    belongs_to :partner_product_type

    def partner_id
      partner_product_type&.partner_id
    end
  end
end
