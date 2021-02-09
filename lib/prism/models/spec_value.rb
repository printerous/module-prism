# frozen_string_literal: true

module Prism
  class SpecValue < PrismModel
    acts_as_paranoid
    # acts_as_taggable

    has_one :spec_component, -> { order(id: :asc) }
    has_one :component, through: :spec_component

    has_many :spec_components

    def component_for(printing_type, **options)
      sc = spec_components.by_rules(options)
                          .find_by(printing_type: printing_type)
      sc&.component
    end

    def active?
      deactivated_at.blank?
    end

    def deactivate!(user)
      update deactivated_at: Time.current, properties: { 'change_by': user.name }
    end

    def activate!(user)
      update deactivated_at: nil, properties: { 'change_by': user.name }
    end

    def self.custom_size
      find_by(code: 'CUSTOM_SIZE')
    end

    def direct?
      properties['is_direct']
    end

    def self.tagged_with(text = [])
      return [] if text.flatten.compact.blank?

      conditions = text.map do |t|
        "LOWER(tags.name) ILIKE '#{t}' ESCAPE '!'"
      end.join(' OR ')

      # select tags first
      tag_ids = Prism::Tag.where(conditions).map(&:id)

      return [] if tag_ids.blank?

      # select tagging
      tagging_ids = Prism::Tagging.where(taggable_type: 'SpecValue')
                                  .where(tag_id: tag_ids)
                                  .map(&:id)

      return [] if tagging_ids.blank?

      where(id: tagging_ids)
    end
  end
end
