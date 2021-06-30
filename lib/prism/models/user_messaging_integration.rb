# frozen_string_literal: true
# == Schema Information
#
# Table name: user_messaging_integrations
#
#  id             :bigint(8)        not null, primary key
#  user_id        :integer
#  messaging_type :string
#  messaging_id   :string
#  data           :jsonb
#  revoked_at     :datetime
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#

module Prism
  class UserMessagingIntegration < PrismModel
    belongs_to :user

    def username
      return nil if data.blank?

      data['username']
    end
  end
end
