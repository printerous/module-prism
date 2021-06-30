# == Schema Information
#
# Table name: product_type_spec_sets
#
#  id              :bigint(8)        not null, primary key
#  product_type_id :bigint(8)
#  spec_set_id     :bigint(8)
#  application     :string           default("prism")
#

module Prism
  class ProductTypeSpecSet < PrismModel
    belongs_to :product_type
    belongs_to :spec_set
  end
end
