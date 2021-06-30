# frozen_string_literal: true
# == Schema Information
#
# Table name: organization_addresses
#
#  id              :bigint(8)        not null, primary key
#  organization_id :bigint(8)
#  types           :jsonb
#  label           :string
#  district_id     :bigint(8)
#  zip_code        :string
#  street          :string
#  pic_name        :string
#  pic_email       :string
#  pic_phone       :string
#  deleted_at      :datetime
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  office_phone    :string
#  integration     :jsonb
#  data            :jsonb
#  user_uniq_id    :string
#  code            :string
#

module Prism
  class OrganizationAddress < PrismModel
    acts_as_paranoid

    belongs_to :organization
    belongs_to :district, optional: true

    has_one :city, through: :district
    has_one :province, through: :city
    has_one :country, through: :province

    has_many :main_addresses

    scope :by_query, lambda { |query|
      return where(nil) if query.blank?

      query = ActiveRecord::Base.connection.quote_string(query.strip)
      eager_load(:district, :city, :province)
        .where("similarity(organization_addresses.label, :query) >= 0.1
          OR similarity(organization_addresses.street, :query) >= 0.1
          OR organization_addresses.street % :query
          OR organization_addresses.label ILIKE :keyword
          OR organization_addresses.pic_email ILIKE :keyword
          OR organization_addresses.pic_name ILIKE :keyword
          OR organization_addresses.pic_phone ILIKE :keyword
          OR organization_addresses.office_phone ILIKE :keyword
          OR districts.name ILIKE :keyword
          OR cities.name ILIKE :keyword
          OR provinces.name ILIKE :keyword", query: query, keyword: "%#{query}%")
        .order(Arel.sql("similarity(organization_addresses.label, '#{query}') DESC"))
        .order(Arel.sql("similarity(organization_addresses.street, '#{query}') DESC"))
    }

    scope :by_city_name, lambda { |query|
      return where(nil) if query.blank?

      eager_load(:city)
        .where('cities.name ILIKE :query', query: "%#{query}%")
    }

    scope :by_district_name, lambda { |query|
      return where(nil) if query.blank?

      eager_load(:district)
        .where('districts.name ILIKE :query', query: "%#{query}")
    }

    scope :by_district_id, lambda { |district_id|
      return where(nil) if district_id.blank?

      where('organization_addresses.district_id = ?', district_id)
    }

    scope :by_city_id, lambda { |city_id|
      return where(nil) if city_id.blank?

      filtered_disctrict = Prism::District.where(city_id: city_id).map(&:id)
      where(district_id: filtered_disctrict)
    }

    def self.search(params = {})
      params = {} if params.blank?
      by_query(params[:query])
        .by_city_id(params[:city_id])
        .by_district_id(params[:district_id])
    end

    def full_address
      [street&.gsub("\r\n", ' '), district&.name, city&.name, province&.name, zip_code].compact.join(', ')
    end

    def address
      [pic_name, full_address].compact.join(', ')
    end

    def main?(user_id)
      main_addresses.find_by(user_id: user_id).present?
    end

    def latitude
      data['lat']
    end

    def longitude
      data['long']
    end

    def latitude=(lat)
      data['lat'] = lat
    end

    def longitude=(long)
      data['long'] = long
    end

    def address_json
      {
        'label': label,
        'zip_code': zip_code,
        'street': street,
        'pic_name': pic_name,
        'pic_email': pic_email,
        'pic_phone': pic_phone,
        'office_phone': office_phone,
        'full_address': full_address,
        'address': address
      }
    end

    def city_name
      city&.name
    end
  end
end
