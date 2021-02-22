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

    attribute :latitude
    attribute :longitude

    belongs_to :organization
    belongs_to :district, optional: true

    has_one :city, through: :district
    has_one :province, through: :city
    has_one :country, through: :province
  end
end
