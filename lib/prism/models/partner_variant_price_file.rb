# frozen_string_literal: true

# == Schema Information
#
# Table name: partner_variant_price_files
#
#  id                 :bigint           not null, primary key
#  partner_variant_id :bigint
#  user_id            :bigint
#  file               :string
#  active_at          :datetime
#  inactive_at        :datetime
#  deleted_at         :datetime
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  recommended        :boolean          default("false")
#  expired_date       :datetime
#  validity_period    :integer
#  agreement_file     :string
#

module Prism
  class PartnerVariantPriceFile < PrismModel
    acts_as_paranoid

    belongs_to :partner_variant
    belongs_to :user

    mount_uploader :file, Prism::PriceUploader
    mount_uploader :agreement_file, Prism::PriceUploader

    scope :active, -> { where('active_at IS NOT NULL AND active_at <= :now AND (inactive_at IS NULL OR inactive_at > :now)', now: Time.zone.now) }

    def variant
      partner_variant.variant
    end
  end
end
