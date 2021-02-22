# frozen_string_literal: true

# == Schema Information
#
# Table name: partner_product_variants
#
#  id                 :bigint           not null, primary key
#  partner_id         :integer
#  product_variant_id :integer
#  deleted_at         :datetime
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  product_type_id    :integer
#  speciality         :boolean
#  availability       :boolean
#  properties         :jsonb
#  variant_id         :integer
#
module Prism
  class PartnerProductVariant < PrismModel
    acts_as_paranoid
  end
end
