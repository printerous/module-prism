# == Schema Information
#
# Table name: organization_product_prices
#
#  id               :bigint(8)        not null, primary key
#  organization_id  :integer
#  product_id       :integer
#  product_price_id :integer
#  quantity         :float            default(0.0)
#  unit             :string
#  currency_code    :string
#  price            :decimal(12, 2)
#  working_day      :integer
#  integrations     :jsonb
#  deleted_at       :datetime
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  cogs             :decimal(12, 2)   default(0.0)
#  quantity_max     :float            default(0.0)
#  project          :string
#  quantity_min     :integer
#  partner_id       :integer
#

module Prism
  class OrganizationProductPrice < PrismModel
    acts_as_paranoid

  end
end
