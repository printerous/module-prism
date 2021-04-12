# == Schema Information
#
# Table name: organizations
#
#  id                 :bigint(8)        not null, primary key
#  parent_id          :integer
#  type               :string
#  name               :string
#  website            :string
#  anniversary        :date
#  phone              :string
#  status             :integer
#  deleted_at         :datetime
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  profile_completion :integer
#  lead_source_id     :integer
#  data               :jsonb
#  code               :string
#  integration        :jsonb
#  is_pro             :integer
#

module Prism
  class Organization < PrismModel
    acts_as_paranoid

    has_many :organization_members, dependent: :destroy
    has_many :people, through: :organization_members

    has_many :organization_addresses, dependent: :destroy
    has_one  :organization_financial_detail, dependent: :destroy
  end
end
