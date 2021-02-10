# frozen_string_literal: true

module Prism
  class City < PrismModel
    acts_as_paranoid

    belongs_to :province

    scope :by_city, lambda { |query|
      return where(nil) if query.blank?

      where(
        'cities.name ILIKE :query OR cities.abbr ILIKE :query',
        query: "%#{query}%"
      )
    }

    scope :by_query, lambda { |query|
      return where(nil) if query.blank?

      where(
        'provinces.name ILIKE :query OR provinces.abbr ILIKE :query
        cities.name ILIKE :query OR cities.abbr ILIKE :query',
        query: "%#{query}%"
      )
    }

    def destination_name
      destination = province&.name.to_s
      destination = "#{destination}, #{city&.name}" unless city.blank?
      destination
    end
  end
end
