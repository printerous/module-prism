# frozen_string_literal: true

module Prism
  class DistanceCalculator
    attr_reader :origin, :destination

    def initialize(origin = [], destination = [], options = {})
      @origin = origin
      @destination = destination
    end

    def calculate
      return unless valid?

      rad_per_deg = Math::PI / 180 # PI / 180
      rkm = 6371                  # Earth radius in kilometers
      # rm = rkm * 1000             # Radius in meters

      dlat_rad = (destination[0] - origin[0]) * rad_per_deg # Delta, converted to rad
      dlon_rad = (destination[1] - origin[1]) * rad_per_deg

      lat1_rad, lon1_rad = origin.map { |i| i * rad_per_deg }
      lat2_rad, lon2_rad = destination.map { |i| i * rad_per_deg }

      a = Math.sin(dlat_rad / 2)**2 + Math.cos(lat1_rad) * Math.cos(lat2_rad) * Math.sin(dlon_rad / 2)**2
      c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a))

      rkm * c # Delta in kma
    end

    def valid?
      valid_origin? && valid_destination?
    end

    def valid_origin?
      origin[0].present? && origin[1].present?
    end

    def valid_destination?
      destination[0].present? && destination[1].present?
    end
  end
end
