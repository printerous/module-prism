# frozen_string_literal: true

module Prism
  class Component < PrismModel
    acts_as_paranoid

    has_many    :components, foreign_key: :parent_id
    belongs_to  :category, class_name: 'Component', foreign_key: :parent_id, optional: true

    has_one     :spec_component, dependent: :destroy
    has_one     :spec_value, through: :spec_component

    has_many    :partner_components
    has_many    :partner_ratecards, through: :partner_components

    has_many    :component_papers
    has_many    :printing_papers, through: :component_papers
    has_many    :ratecard_journey_components, dependent: :destroy

    def price?
      properties['price'] || false
    end

    def tier?
      properties['allow_tier'] || false
    end

    def paper_base
      printing_papers.base.first
    end

    def partner_ratecard(partner, version = 'ALL')
      partner_ratecards.find {|ratecard|
        ratecard.partner_id == partner.id && ratecard.version == version
      }
    end

    def bbs?
      return true unless properties.key?('bbs')
      properties['bbs']
    end
  end
end
