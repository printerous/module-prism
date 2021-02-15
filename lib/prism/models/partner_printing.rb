# == Schema Information
#
# Table name: partners
#
#  id                  :bigint(8)        not null, primary key
#  type                :string
#  name                :string
#  legal_name          :string
#  phone               :string
#  email               :string
#  province_id         :integer
#  city_id             :integer
#  address             :text
#  logo                :string
#  pic_name            :string
#  pic_phone           :string
#  pic_email           :string
#  status              :integer
#  tags                :string
#  deleted_at          :datetime
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  source_type         :string
#  source_id           :integer
#  properties          :jsonb
#  karma_score         :jsonb
#  latitude            :float
#  longitude           :float
#  district_id         :bigint(8)
#  zip_code            :string
#  rank                :integer
#  workshop_address    :string
#  established_year    :string
#  employee_size       :integer
#  pic_role            :string
#  daily_spk           :integer
#  production_capacity :integer
#  valuable_clients    :text
#  owned_machine       :jsonb
#  own_logistic        :integer
#  covered_area        :text
#  thirdparty_logistic :text
#  own_packing         :jsonb
#  products_image      :jsonb
#  counter             :jsonb
#

require File.dirname(__FILE__) + '/partner.rb'

module Prism
  class PartnerPrinting < Prism::Partner
    acts_as_paranoid

    def self.printerous
      PartnerPrinting.find_by("properties ? 'is_printerous'") ||
        PartnerPrinting.find_by(id: 1)
    end
  end
end
