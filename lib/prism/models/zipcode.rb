module Prism
  class Zipcode < PrismModel
    acts_as_paranoid

    belongs_to :district, optional: true

    scope :by_query, lambda { |query|
      return where(nil) if query.blank?

      where(
        'zipcode ILIKE :query OR sub_district_name ILIKE :query OR
        district_name ILIKE :query OR city_name ILIKE :query OR
        province_name ILIKE :query',
        query: "%#{query}%"
      )
    }

    def self.search(params = {})
      params = {} if params.blank?

      by_query(params[:query])
    end

    def full_address_name
      "#{sub_district_name}, #{district_name}, #{city_name}, #{province_name}"
    end
  end
end