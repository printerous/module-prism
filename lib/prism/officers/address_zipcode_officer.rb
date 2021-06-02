# frozen_string_literal: true

module Prism
  class AddressZipcodeOfficer
    attr_reader :address

    def initialize(address)
      @address = address
    end

    def perform
      zipcode = Prism::Zipcode.find_by(zipcode: address.zip_code)
      return true if zipcode.present?

      district = address.district
      return if district.blank?

      zipcode = Prism::Zipcode.new
      zipcode.zipcode       = address.zip_code&.strip
      zipcode.city_id       = district.city_id
      zipcode.district_name = district.name
      zipcode.city_name     = district.city&.name
      zipcode.province_name = district.city&.province&.name
      zipcode.save
    end
  end
end
