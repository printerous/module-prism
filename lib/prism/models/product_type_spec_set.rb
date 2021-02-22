# == Schema Information
#
# Table name: product_type_spec_sets
#
#  id              :bigint           not null, primary key
#  product_type_id :bigint
#  spec_set_id     :bigint
#  application     :string           default("prism")
#

module Prism
  class ProductTypeSpecSet < PrismModel
    belongs_to :product_type
    belongs_to :spec_set
  end
end
