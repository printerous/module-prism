# frozen_string_literal: true

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

module Prism
  class Partner < PrismModel
    acts_as_paranoid

    belongs_to :city
    belongs_to :province
    belongs_to :district

    has_many :partner_machines
    has_many :printing_machines, through: :partner_machines

    has_many :active_partner_machines, -> { where(deactivated_at: nil).where('activated_at IS NOT NULL') }, class_name: 'PartnerMachine', foreign_key: :partner_id
    has_many :active_printing_machines, through: :active_partner_machines, source: :printing_machine

    has_many :partner_ratings
    has_one  :alltime, -> { where(period: 'alltime') }, class_name: 'PartnerRating'
    has_one  :current_mtd, -> { where(period: 'mtd').where(end_date: Date.yesterday) }, class_name: 'PartnerRating'
    has_many :three_months_before, -> { where(period: 'monthly').where(name: (1..3).to_a.map { |i| (Date.today - i.month).strftime('%b %Y') }).order(created_at: 'desc') }, class_name: 'PartnerRating'

    has_many :partner_product_variants
    has_many :partner_product_types
    has_many :partner_variants, through: :partner_product_types

    enum status: %i[active inactive banned]

    scope :active, lambda {
      where(status: :active)
    }

    scope :by_name, lambda { |name|
      return where(nil) if name.blank?

      where(
        'partners.name ILIKE :name OR partners.legal_name ILIKE :name',
        name: "%#{name}%"
      )
    }

    def self.options
      all.collect { |p| [p.name, p.id] }
    end

    def daf_off_additional(working_day = 1)
      close_date = properties['close_date']
      open_date  = properties['open_date']
      return 0 if [close_date, open_date].any?(&:blank?)

      now      = Time.zone.now
      deadline = now + working_day.days

      # Jika hari ini sudah buka lagi
      # atau deadline jatuh sebelum tutup
      return 0 if now > open_date || deadline < close_date

      # Jika hari ini dalam masa libur
      return (Date.parse(open_date) - Date.today).to_i if now > close_date

      # Jika deadline ketika partner sedang tutup
      (Date.parse(open_date) - Date.parse(close_date)).to_i
    end
  end
end
