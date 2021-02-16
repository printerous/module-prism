# == Schema Information
#
# Table name: partner_product_types
#
#  id              :bigint(8)        not null, primary key
#  partner_id      :bigint(8)
#  product_type_id :integer
#  availability    :integer          default(1)
#  deleted_at      :datetime
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  properties      :jsonb
#

module Prism
  class PartnerProductType < PrismModel
    acts_as_paranoid
  end
end
