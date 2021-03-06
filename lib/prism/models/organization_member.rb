# == Schema Information
#
# Table name: organization_members
#
#  id                :bigint(8)        not null, primary key
#  people_id         :bigint(8)
#  organization_id   :bigint(8)
#  phone             :string
#  position          :string
#  printing_priority :string
#  active_at         :datetime
#  inactive_at       :datetime
#  deleted_at        :datetime
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  position_type_id  :integer
#  job_title         :string
#

module Prism
  class OrganizationMember < PrismModel
    acts_as_paranoid

    belongs_to :person, -> { with_deleted }, foreign_key: :people_id

    belongs_to :personal, foreign_key: :organization_id
    belongs_to :organization, -> { with_deleted }
    belongs_to :company, -> { with_deleted }, foreign_key: :organization_id
  end
end
