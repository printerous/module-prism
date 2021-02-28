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

    belongs_to :district, optional: true

    scope :by_query, lambda { |query|
      return where(nil) if query.blank?

      query = ActiveRecord::Base.connection.quote_string(query.strip)
      where("zipcodes.zipcode % :query OR zipcodes.sub_district_name % :query OR
         zipcodes.district_name % :query OR zipcodes.city_name % :query OR
         zipcodes.province_name % :query", query: query, code: "%#{query}%")
        .order(Arel.sql("similarity(zipcodes.zipcode, '#{query}') DESC"))
        .order(Arel.sql("similarity(zipcodes.sub_district_name, '#{query}') DESC"))
        .order(Arel.sql("similarity(zipcodes.district_name, '#{query}') DESC"))
        .order(Arel.sql("similarity(zipcodes.city_name, '#{query}') DESC"))
        .order(Arel.sql("similarity(zipcodes.province_name, '#{query}') DESC"))
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
