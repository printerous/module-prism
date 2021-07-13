# == Schema Information
#
# Table name: organization_product_shippings
#
#  id                              :bigint(8)        not null, primary key
#  organization_product_price_id   :bigint(8)
#  organization_shipping_config_id :bigint(8)
#  deleted_at                      :datetime
#  created_at                      :datetime         not null
#  updated_at                      :datetime         not null
#

module Prism
  class OrganizationProductShipping < PrismModel
  end
end
