# == Schema Information
#
# Table name: product_types
#
#  id          :bigint           not null, primary key
#  code        :string
#  name        :string
#  tags        :string
#  deleted_at  :datetime
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  active_at   :datetime
#  inactive_at :datetime
#  spec_set_id :bigint
#  integration :jsonb
#

module Prism
  class ProductType < PrismModel
    acts_as_paranoid

    has_many :products
    has_many :product_variants, class_name: 'Stark::ProductVariant', foreign_key: :product_type_id
    has_many :active_variants, -> { active }, class_name: 'Stark::ProductVariant', foreign_key: :product_type_id

    has_many :product_type_spec_sets, class_name: 'Prism::ProductTypeSpecSet'
    has_many :spec_sets, through: :product_type_spec_sets, class_name: 'Prism::SpecSet', source: :spec_set
    has_many :spec_wizards, through: :spec_sets

    has_one  :prism_product_type_spec_set, -> { where(application: 'prism') }, class_name: 'Prism::ProductTypeSpecSet'
    has_one  :prism_spec_set, through: :prism_product_type_spec_set, class_name: 'Prism::SpecSet', source: :spec_set
    has_many :prism_spec_wizards, through: :prism_spec_set, source: :spec_wizards

    has_one  :website_product_type_spec_set, -> { where(application: 'website') }, class_name: 'Prism::ProductTypeSpecSet'
    has_one  :website_spec_set, through: :website_product_type_spec_set, class_name: 'Prism::SpecSet', source: :spec_set
    has_many :website_spec_wizards, through: :website_spec_set, source: :spec_wizards
  end
end
