# frozen_string_literal: true

# == Schema Information
#
# Table name: partner_ratecards
#
#  id                   :bigint(8)        not null, primary key
#  partner_id           :bigint(8)
#  partner_component_id :bigint(8)
#  version              :string
#  currency             :string
#  unit                 :jsonb
#  deleted_at           :datetime
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  active_at            :datetime
#  inactive_at          :datetime
#  price_minimum        :decimal(, )
#  printing_type        :string
#  properties           :jsonb
#


module Prism
  class PartnerRatecard < PrismModel
    acts_as_paranoid

    belongs_to :partner
    belongs_to :partner_component

    has_one   :component, through: :partner_component
    has_many  :partner_ratecard_tiers, dependent: :destroy
    has_many  :tiers, -> { order(:quantity_top) }, class_name: 'PartnerRatecardTier'

    scope :offsets, -> { where(printing_type: ['', :offset]) }
    scope :digitals, -> { where printing_type: :digital }
    scope :digital_ecos, -> { where printing_type: :digital_eco }
    scope :large_formats, -> { where printing_type: :large_format }
    scope :corrugateds, -> { where printing_type: :corrugated }

    def self.active_component
      joins(:component).where('partner_components.activated_at IS NOT NULL')
    end

    def self.active_ratecard
      where('active_at IS NOT NULL AND inactive_at IS NULL')
    end

    def self.search(params = {})
      params = {} if params.blank?

      by_partner(params[:partner])
    end

    def active?
      !active_at.nil? && inactive_at.nil?
    end

    def deactive?
      active_at.nil? && !inactive_at.nil?
    end

    def activate!
      update(active_at: Time.current, inactive_at: nil)
    end

    def deactivate!
      update(active_at: nil, inactive_at: Time.current)
    end

    def try_destroy!
      return if partner_ratecard_tiers.present?

      destroy
    end

    def props
      properties || {}
    end
  end
end
