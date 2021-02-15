# frozen_string_literal: true

# == Schema Information
#
# Table name: partner_components
#
#  id                    :bigint(8)        not null, primary key
#  partner_id            :bigint(8)
#  component_id          :bigint(8)
#  properties            :jsonb
#  unit                  :jsonb
#  deleted_at            :datetime
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  activated_at          :datetime
#  deactivated_at        :datetime
#  activation_changed_by :bigint(8)
#


module Prism
  class PartnerComponent < PrismModel
    acts_as_paranoid

    belongs_to :partner
    belongs_to :component
    belongs_to :activation_actor, class_name: 'User', foreign_key: :activation_changed_by, optional: true

    has_many :partner_ratecards, dependent: :destroy
    has_many :partner_ratecard_tiers, through: :partner_ratecards

    has_one  :partner_ratecard_insheet, -> { where(version: 'jumlah_insheet') }, class_name: 'PartnerRatecard'

    def active?
      !activated_at.nil? && deactivated_at.nil?
    end

    def deactive?
      activated_at.nil? && !deactivated_at.nil?
    end
  end
end
