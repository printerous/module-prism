# == Schema Information
#
# Table name: social_accounts
#
#  id         :bigint           not null, primary key
#  user_id    :bigint
#  uid        :string
#  provider   :string
#  connected  :boolean
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  email      :string
#

module Prism
  class SocialAccount < PrismModel
    belongs_to :user
  end
end
