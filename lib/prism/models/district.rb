# == Schema Information
#
# Table name: districts
#
#  id          :bigint(8)        not null, primary key
#  name        :string
#  city_id     :bigint(8)
#  deleted_at  :datetime
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  integration :jsonb
#  latitude    :float            default(0.0)
#  longitude   :float            default(0.0)
#  code        :string
#

module Prism
  class District < PrismModel
    acts_as_paranoid

    belongs_to :city

    scope :by_query, lambda { |query|
      return where(nil) if query.blank?

      query = ActiveRecord::Base.connection.quote_string(query.strip)
      joins(:city)
        .where("districts.name % :query OR REGEXP_REPLACE(districts.code, '\s', '', 'g') ILIKE :code OR cities.name % :query", query: query, code: "%#{query}%")
        .order(Arel.sql("similarity(cities.name, '#{query}') DESC"))
        .order(Arel.sql("similarity(districts.name, '#{query}') DESC"))
    }

    scope :by_city_id, lambda { |city_id|
      return where(nil) if city_id.blank?

      where(city_id: city_id)
    }

    scope :by_id, lambda { |id|
      return where(nil) if id.blank?

      where("districts.id = ?", id)
    }

    scope :column_selection, lambda { |latitude, longitude|
      return select("#{Prism::District.table_name}.*") if [latitude, longitude].any?(&:blank?)

      select("#{Prism::District.table_name}.*, #{distance_selector(latitude, longitude)}").order('distance asc')
    }

    def self.search(params = {})
      params = {} if params.blank?

      column_selection(params[:latitude], params[:longitude])
        .by_query(params[:query])
        .by_city_id(params[:city_id])
        .by_id(params[:id])
    end

    def self.default_origin
      by_query('Kebon Jeruk').first
    end

    private

    def self.distance_selector(latitude, longitude)
      sql = <<~SQL
        (6371 *
          ACOS(
            COS(RADIANS(#{latitude})) *
            COS(RADIANS(districts.latitude)) *
              COS(RADIANS(districts.longitude) - RADIANS(#{longitude})
            ) +
            SIN(RADIANS(#{latitude})) *
            SIN(RADIANS(districts.latitude))
          )
        ) AS distance
      SQL

      sql
    end
  end
end
