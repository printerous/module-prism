# frozen_string_literal: true

# == Schema Information
#
# Table name: cities
#
#  id          :bigint(8)        not null, primary key
#  province_id :bigint(8)
#  abbr        :string
#  name        :string
#  tags        :string
#  deleted_at  :datetime
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  integration :jsonb
#  latitude    :float            default(0.0)
#  longitude   :float            default(0.0)
#

module Prism
  class City < PrismModel
    acts_as_paranoid

    belongs_to :province
    has_many   :districts

    scope :by_city, lambda { |query|
      return where(nil) if query.blank?

      query = ActiveRecord::Base.connection.quote_string(query.strip)
      where("cities.name % :query", query: query, code: "%#{query}%")
        .order(Arel.sql("similarity(cities.name, '#{query}') DESC"))
    }

    scope :by_query, lambda { |query|
      return where(nil) if query.blank?

      where('provinces.name ILIKE :query OR provinces.abbr ILIKE :query
        cities.name ILIKE :query OR cities.abbr ILIKE :query',
        query: "%#{query}%"
      )
    }

    scope :by_id, lambda { |id|
      return where(nil) if id.blank?

      where("cities.id = ?", id)
    }

    scope :by_province_id, lambda { |province_id|
      return where(nil) if province_id.blank?

      where(province_id: province_id)
    }

    def self.search(params = {})
      params = {} if params.blank?
      by_city(params[:query])
        .by_province_id(params[:province_id])
        .by_id(params[:id])
    end

    def destination_name
      destination = province&.name.to_s
      destination = "#{destination}, #{city&.name}" unless city.blank?
      destination
    end
  end
end
