# == Schema Information
#
# Table name: people
#
#  id                  :bigint(8)        not null, primary key
#  name                :string
#  email               :string
#  phone               :string
#  gender              :string
#  language            :integer
#  date_of_birth       :date
#  email_notifications :jsonb
#  deleted_at          :datetime
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  data                :jsonb
#  integration         :jsonb
#

module Prism
  class Person < PrismModel
    acts_as_paranoid

    has_one  :person_account, dependent: :destroy
    has_one  :user, through: :person_account

    has_many :organization_members, foreign_key: :people_id, dependent: :destroy
    has_many :organizations, through: :organization_members

    has_one  :organization_member, foreign_key: :people_id
    has_one  :personal, through: :organization_member
  end
end
