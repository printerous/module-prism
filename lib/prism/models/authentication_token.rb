# == Schema Information
#
# Table name: authentication_tokens
#
#  id            :bigint(8)        not null, primary key
#  resource_type :string           not null
#  resource_id   :string           not null
#  token         :string           not null
#  session_id    :string           not null
#  ip_address    :string
#  user_agent    :string
#  active_at     :datetime
#  inactive_at   :datetime
#  deleted_at    :datetime
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#

module Prism
  class AuthenticationToken < PrismModel
    acts_as_paranoid

    belongs_to :resource, polymorphic: true

    def self.actives
      now = Time.zone.now

      where('active_at IS NOT NULL AND active_at <= ?', now)
        .where('inactive_at IS NULL OR inactive_at > ?', now)
    end

    def activate!(inactive_at: 2.days.from_now)
      update active_at: Time.zone.now, inactive_at: inactive_at
    end

    def inactivate!
      update inactive_at: Time.zone.now
    end
  end
end
