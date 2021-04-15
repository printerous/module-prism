# frozen_string_literal: true

module Prism
  class PartnerFinder
    attr_reader :variant_id, :options, :exclude

    def initialize(variant_id, args = {})
      @variant_id = variant_id
      @options    = args&.to_h&.with_indifferent_access
      @exclude    = [options[:exclude]].flatten.compact
    end

    def perform
      Prism::Partner.find_by_sql(finder_sql).uniq(&:id)
    end

    def partners
      return [] unless valid_params?

      first_partner = Prism::PartnerFinder.new(variant_id, options).perform.first
      return [] if first_partner.blank?

      [first_partner, surrounding_partners(first_partner, priority: first_partner.priority)].flatten.delete_if(&:blank?)
    end

    def surrounding_partners(first_partner, priority: false)
      return [] if [first_partner.latitude, first_partner.longitude].any?(&:blank?)

      surr_options = options.merge(
        latitude: first_partner.latitude,
        longitude: first_partner.longitude,
        priority: priority,
        distance: 25,
        exclude: first_partner.id
      )

      surroundings = Prism::PartnerFinder.new(variant_id, surr_options).perform
      surroundings.each do |partner|
        distance = Prism::DistanceCalculator.new(
          [partner.latitude, partner.longitude],
          [options[:latitude].to_f, options[:longitude].to_f],
          { units: :km }
        ).calculate

        partner.distance = distance
      end

      surroundings
    end

    private

    def valid_params?
      variant_id.present? && valid_location?
    end

    def valid_location?
      latitude.present? && longitude.present?
    end

    def latitude
      options[:latitude]
    end

    def longitude
      options[:longitude]
    end

    def finder_sql
      sql = <<~SQL
        SELECT *
        FROM (
          #{subquery}
        ) AS filtered_partners
      SQL

      conditions = [true]
      conditions << "distance <= #{options[:distance]}" if options[:distance].present?

      [sql, conditions.join(' AND ')].join(' WHERE ') + ' LIMIT 25'
    end

    def subquery
      sql = <<~SQL
        SELECT partners.*, partner_variants.priority, partner_ratings.score as rating, (6371 *
          ACOS(
            COS(RADIANS(#{latitude})) *
            COS(RADIANS(latitude)) *
              COS(RADIANS(longitude) - RADIANS(#{longitude})
            ) +
            SIN(RADIANS(#{latitude})) *
            SIN(RADIANS(latitude))
          )
        ) AS distance
        FROM partners
          JOIN partner_product_types ON partners.id = partner_product_types.partner_id
            AND partner_product_types.deleted_at IS NULL
          JOIN partner_variants ON partner_product_types.id = partner_variants.partner_product_type_id
            AND partner_variants.deleted_at IS NULL
          LEFT JOIN partner_ratings ON partners.id = partner_ratings.partner_id
            AND partner_ratings.deleted_at is NULL
            AND partner_ratings.period = 'alltime'
      SQL

      conditions = [true]
      conditions << "partner_variants.variant_id = #{variant_id}"
      conditions << 'partner_variants.benchmark = true'
      conditions << 'partners.latitude IS NOT NULL'
      conditions << 'partners.longitude IS NOT NULL'
      conditions << 'partners.deleted_at IS NULL'
      conditions << "partners.status = #{Prism::Partner.statuses[:active]}"

      conditions << "partner_variants.priority = #{options['priority']}" if options.key?('priority')
      conditions << "partners.id NOT IN (#{exclude.join(',')})" if exclude.present?

      [sql, conditions.join(' AND ')].join(' WHERE ') + ' ORDER BY partner_variants.priority DESC, distance ASC'
    end
  end
end
