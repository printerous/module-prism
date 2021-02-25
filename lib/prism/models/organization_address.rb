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

    def full_address
      [street.gsub("\r\n", ' '), district&.name, city&.name, province&.name, zip_code].compact.join(', ')
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

    scope :by_query, lambda { |query|
      return where(nil) if query.blank?

      eager_load(:district, :city, :province)
        .where("organization_addresses.label % :query OR organization_addresses.street % :query OR
          organization_addresses.pic_email ILIKE :query OR
          organization_addresses.pic_name ILIKE :query OR
          organization_addresses.pic_phone ILIKE :query OR
          organization_addresses.office_phone ILIKE :query OR
          districts.name ILIKE :query OR
          cities.name ILIKE :query OR
          provinces.name ILIKE :query", query: query, code: "%#{query}%")  
        .order(Arel.sql("similarity(organization_addresses.label, '#{query}') DESC"))
        .order(Arel.sql("similarity(organization_addresses.street, '#{query}') DESC"))
    }

    def self.search(params = {})
      params = {} if params.blank?
      by_query(params[:query])
    end
  end
end
