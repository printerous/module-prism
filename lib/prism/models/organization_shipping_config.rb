# == Schema Information
#
# Table name: organization_shipping_configs
#
#  id                                   :bigint(8)        not null, primary key
#  organization_product_price_id        :bigint(8)
#  source_address_type                  :string
#  source_address_id                    :integer
#  destination_address_type             :string
#  destination_address_id               :integer
#  logistic_shipping_courier_service_id :bigint(8)
#  price                                :integer
#  created_at                           :datetime         not null
#  updated_at                           :datetime         not null
#

module Prism
  class OrganizationShippingConfig < PrismModel
    acts_as_paranoid

  end
end
