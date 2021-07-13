# == Schema Information
#
# Table name: organization_product_shippings
#
#  id                               :bigint(8)        not null, primary key
#  organization_shipping_config_id  :bigint(8)
#  deleted_at                       :datetime
#  created_at                       :datetime         not null
#  updated_at                       :datetime         not null
#  organization_partner_coverage_id :bigint(8)
#

module Prism
  class OrganizationProductShipping < PrismModel
  end
end
