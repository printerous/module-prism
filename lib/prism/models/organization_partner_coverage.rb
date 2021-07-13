# == Schema Information
#
# Table name: organization_partner_coverages
#
#  id                            :bigint(8)        not null, primary key
#  organization_product_price_id :integer
#  area_type                     :string
#  area_id                       :integer
#  deleted_at                    :datetime
#  created_at                    :datetime         not null
#  updated_at                    :datetime         not null
#  integrations                  :jsonb
#

module Prism
  class OrganizationPartnerCoverage < PrismModel
    acts_as_paranoid

  end
end
