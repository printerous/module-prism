# frozen_string_literal: true

module Stark
  module Activable
    module ClassMethods
      def active
        actives
      end

      def actives
        now = Time.zone.now

        where("#{table_name}.active_at IS NOT NULL AND #{table_name}.active_at <= ?", now)
          .where("#{table_name}.inactive_at IS NULL OR #{table_name}.inactive_at > ?", now)
      end

      def inactive
        inactives
      end

      def inactives
        now = Time.zone.now

        where("#{table_name}.active_at IS NULL OR #{table_name}.active_at > :now
          OR (#{table_name}.inactive_at IS NOT NULL AND #{table_name}.inactive_at <= :now)", now: now)
      end

      def activate!(inactive_at: nil)
        update_all active_at: Time.zone.now, inactive_at: inactive_at
      end

      def inactivate!
        update_all inactive_at: Time.zone.now
      end
    end

    def self.included(receiver)
      receiver.extend ClassMethods
    end

    def activate!(inactive_at: nil)
      update active_at: Time.zone.now, inactive_at: inactive_at
    end

    def inactivate!
      update inactive_at: Time.zone.now
    end

    def toggle_activate!
      return inactivate! if active?

      activate!
    end

    def ensure_activation
      return active_at if active?

      self.inactive_at = nil
      self.active_at = Time.zone.now
    end

    def ensure_inactivation
      return inactive_at if inactive?

      self.active_at = nil
      self.inactive_at = Time.zone.now
    end

    def active?
      now = Time.zone.now
      active_at.present? && active_at <= now && (inactive_at.blank? || inactive_at > now)
    end

    def inactive?
      !active?
    end
  end
end
