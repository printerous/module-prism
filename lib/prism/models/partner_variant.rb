# == Schema Information
#
# Table name: partner_variants
#
#  id                      :bigint(8)        not null, primary key
#  partner_product_type_id :bigint(8)
#  variant_id              :integer
#  spec_ids                :jsonb
#  deleted_at              :datetime
#  created_at              :datetime         not null
#  updated_at              :datetime         not null
#  benchmark               :boolean          default(FALSE)
#  cogs_method             :jsonb
#  latest_updated_by       :integer
#  latest_updated_date     :datetime
#  priority                :boolean          default(FALSE)
#

module Prism
  class PartnerVariant < PrismModel
    acts_as_paranoid

    PRICE_SOURCE = {
      'price_list' => 'Price List',
      'offset_calculator' => 'Ratecard Offset',
      'digital_calculator' => 'Ratecard Digital',
      'digital_eco_calculator' => 'Ratecard Digital Eco',
      'large_format_calculator' => 'Ratecard Large Format',
      'corrugated_calculator' => 'Ratecard Corrugated'
    }.freeze

    RATECARD_MAPPER = {
      'offset_calculator' => 'Offset Calculator',
      'digital_calculator' => 'Digital Calculator',
      'digital_eco_calculator' => 'Digital Eco Calculator',
      'large_format_calculator' => 'Large Format Calculator',
      'corrugated_calculator' => 'Corrugated Calculator'
    }.freeze

    belongs_to :variant, class_name: 'Cuanki::Variant'
    belongs_to :partner_product_type
    has_one    :partner, through: :partner_product_type

    has_many   :partner_variant_price_files, dependent: :destroy, class_name: 'Prism::PartnerVariantPriceFile'
    has_one    :active_partner_variant_price_file, -> { active.order(created_at: :desc) }, class_name: 'PartnerVariantPriceFile'

    scope :by_partner_variant, lambda { |partner_id, variant_id|
      eager_load(:partner_product_type)
        .where('partner_product_types.partner_id = ?', partner_id)
        .where(variant_id: variant_id)
    }

    def partner_id
      partner_product_type&.partner_id
    end

    def priority!
      self.priority = true
      save
    end

    def not_priority!
      self.priority = false
      save
    end
  end
end
