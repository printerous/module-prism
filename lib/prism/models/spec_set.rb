#
# == Schema Information
#
# Table name: spec_sets
#
#  id         :bigint(8)        not null, primary key
#  name       :string
#  deleted_at :datetime
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  code       :string
#

module Prism
  class SpecSet < PrismModel
    acts_as_paranoid

    has_many :spec_wizards, -> { order(position: :asc) }, dependent: :destroy
    has_many :spec_values, through: :spec_wizards

    has_many :product_type_spec_sets
    has_many :product_types, through: :product_type_spec_sets

    has_many :website_product_type_spec_set, -> { where(application: 'website') }, class_name: 'ProductTypeSpecSet'
    has_many :website_product_type, through: :website_product_type_spec_set, class_name: 'SpecSet', source: :product_type

    has_many :prism_product_type_spec_set, -> { where(application: 'prism') }, class_name: 'ProductTypeSpecSet'
    has_many :prism_product_type, through: :prism_product_type_spec_set, class_name: 'SpecSet', source: :product_type
  end
end
