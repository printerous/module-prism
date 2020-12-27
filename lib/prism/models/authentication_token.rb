module Prism
  class AuthenticationToken < PrismModel
    acts_as_paranoid

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
