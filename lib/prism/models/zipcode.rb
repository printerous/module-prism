# == Schema Information
#
# Table name: zipcodes
#
#  id                :bigint(8)        not null, primary key
#  district_id       :bigint(8)
#  zipcode           :string
#  sub_district_name :string
#  district_name     :string
#  city_name         :string
#  province_name     :string
#  deleted_at        :datetime
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#

module Prism
  class Zipcode < PrismModel
    acts_as_paranoid

    belongs_to :city, optional: true

    scope :by_query, lambda { |query|
      return where(nil) if query.blank?

      query = ActiveRecord::Base.connection.quote_string(query.strip)
      where('zipcodes.zipcode ILIKE :query', query: "%#{query}%")
    }

    scope :by_city, lambda { |city_id|
      return where(nil) if city_id.blank?

      where(city_id: city_id)
    }

    scope :by_district, lambda { |district_id|
      return where(nil) if district_id.blank?

      district = District.find(district_id)
      where(city_id: district.city_id)
    }

    def self.search(params = {})
      params = {} if params.blank?

      by_query(params[:query])
        .by_city(params[:city_id])
        .by_district(params[:district_id])
    end

    def full_address_name
      "#{sub_district_name}, #{district_name}, #{city_name}, #{province_name}"
    end
  end
end
