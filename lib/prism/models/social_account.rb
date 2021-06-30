# == Schema Information
#
# Table name: social_accounts
#
#  id         :bigint(8)        not null, primary key
#  user_id    :bigint(8)
#  uid        :string
#  provider   :string
#  connected  :boolean
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  email      :string
#  name       :string
#

module Prism
  class SocialAccount < PrismModel
    belongs_to :user, touch: true
  end
end
