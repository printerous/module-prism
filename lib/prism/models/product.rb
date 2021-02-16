# == Schema Information
#
# Table name: products
#
#  id                  :bigint(8)        not null, primary key
#  product_type_id     :bigint(8)
#  code                :string
#  name                :string
#  spec                :jsonb
#  deleted_at          :datetime
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  data                :jsonb
#  tags                :string
#  inquiry_items_count :integer
#  standard_at         :datetime
#

module Prism
  class Product < PrismModel
    acts_as_paranoid

    belongs_to :product_type

    scope :by_spec_id, lambda { |spec_id|
      return where(nil) if spec_id.blank?

      where("products.data -> 'spec_id' = ?", spec_id.to_json)
    }

    scope :by_custom_size, lambda { |custom_size|
      return where(nil) if custom_size.blank?

      where("products.data ? 'size'")
        .where("products.data -> 'size' ->> 'width' = ?", custom_size[:width]&.to_s)
        .where("products.data -> 'size' ->> 'length' = ?", custom_size[:length]&.to_s)
    }

    def _spec
      return {} if data.nil?

      data['spec_id'].with_indifferent_access
    end
    alias_method :spec_id, :_spec
  end
end
