# == Schema Information
#
# Table name: order_references
#
#  id              :bigint(8)        not null, primary key
#  reference_type  :string
#  order_mass_id   :bigint(8)
#  order_proof_id  :bigint(8)
#  proof_type      :string
#  approval_type   :string
#  color_tolerance :boolean
#  deleted_at      :datetime
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  is_main         :boolean          default(FALSE)
#

module Prism
  class OrderReference < PrismModel
    REFERENCE_TYPE = %w[proof mass reorder reprint].freeze
    PROOF_TYPES    = %w[design_file printed_product].freeze
    APPROVAL_TYPES = %w[digital physical].freeze

    belongs_to :order_mass, class_name: 'OrderItem'
    belongs_to :order_proof, class_name: 'OrderItem'

    def self.approval_type_options
      self::APPROVAL_TYPES.map { |type| [type.humanize.capitalize, type] }
    end

    def self.proof_type_options
      [
        ['Proof File', 'design_file'],
        ['Proof Print', 'printed_product']
      ]
    end
  end
end
