# frozen_string_literal: true

module Prism
  module ApplicationHelper
    def idr(number, user_options = {})
      options = {
        delimiter: '.', separator: ',',
        unit: 'Rp', precision: 2
      }.merge(user_options)

      number_to_currency(number, options)
    end

    def num_to_cur(number, cur_code)
      number    = number&.to_f || 0
      cur_code  = cur_code&.upcase
      precision = cur_code == 'IDR' ? 2 : 3
      precision = 2 if number.present? && number.modulo(1).zero?

      currency = Currency.find_by(code: cur_code) || Currency.first
      options  = { delimiter: ',', separator: '.', unit: currency.sign, precision: precision, format: '%u %n' }

      options.merge!(delimiter: '.', separator: ',') unless currency.code.casecmp('IDR')

      number_to_currency(number, options)
    end

    def number(number, **args)
      options = {
        delimiter: '.', separator: ',', precision: 0
      }.merge(args)

      number_with_precision(number, options)
    end

    def number_decimal(number)
      number(number, delimiter: '.', separator: ',', precision: 2)
    end

    def pluralize_formatted(number, unit)
      "#{number(number)} #{unit.try(:pluralize)}"
    end

    def time_difference_day_hour(start_time, end_time)
      return '-' if start_time.blank? || end_time.blank?

      diff = (end_time - start_time) / (24 * 60 * 60)

      suffix = 'togo'
      suffix = 'late' if diff < 0

      timediff   = TimeDifference.between(start_time, end_time).in_general
      daysdiff   = TimeDifference.between(start_time, end_time).in_days
      days       = "#{daysdiff.to_i} days "
      hours      = timediff[:hours].zero? ? '' : "#{timediff[:hours]} hours "
      hours      = timediff[:minutes].zero? ? '' : "#{timediff[:minutes]} minutes " if hours == ''

      "#{days}#{hours} #{suffix}"
    end

    def find_or_build_ratecards(params)
      params[:ratecards].find { |rc| rc.component == params[:component] && rc.printing_type == params[:printing_type] && rc.version == params[:version] } ||
        current_partner.partner_ratecards.build(printing_type: params[:printing_type], version: params[:version], component: params[:component], unit: params[:unit])
    end

    def find_or_build_partner_ratecards(params)
      params[:ratecards].find { |rc| rc.component == params[:component] && rc.printing_type == params[:printing_type] && rc.version == params[:version] } ||
        params[:partner_printing].partner_ratecards.build(printing_type: params[:printing_type], version: params[:version], component: params[:component], unit: params[:unit])
    end

    def calculator_hour(hours)
      office_hours = 8
      durations    = []

      day = (hours / office_hours).to_i
      durations << "#{day} days" if day > 0
      durations << "#{(hours % office_hours).to_i} hours"

      durations.join(' ')
    end

    def sort_by(field, direction)
      arrow = 'down'
      arrow = 'up' if direction.try(:upcase) == 'DESC'

      new_direction = if direction.blank? || direction.try(:upcase) == 'DESC'
                        'ASC'
                      else
                        'DESC'
                      end

      link_to params.to_unsafe_h.merge(sort_by: field, sort_direction: new_direction) do
        content_tag(:i, '', class: "fa fa-angle-#{arrow} ml-8 ")
      end
    end

    def date_format(date, format = 'default')
      syntax = '%d %b %Y'
      syntax = '%d %b %Y %H:%M' if %w[long with_time].include?(format)
      syntax = "%d %b '%y" if %w[short simple].include?(format)
      syntax = '%Y-%m-%d' if %w[iso].include?(format)
      syntax = '%b-%Y' if %w[mon_year].include?(format)

      date.try(:strftime, syntax)
    end
  end
end
