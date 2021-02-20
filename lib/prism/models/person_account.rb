# == Schema Information
#
# Table name: person_accounts
#
#  id         :bigint(8)        not null, primary key
#  person_id  :bigint(8)
#  user_id    :bigint(8)
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

module Prism
  class PersonAccount < PrismModel
    belongs_to :person
    belongs_to :user, -> { with_deleted }
  end
end
