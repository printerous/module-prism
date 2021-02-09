# frozen_string_literal: true

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
