# frozen_string_literal: true

module Prism
  class TermGenerator
    attr_reader :order

    def initialize(order)
      @order = order
    end

    def perform
      return if order.term_of_invoice.blank?

      puts order.term_of_invoice

      type = order.term_of_invoice['type']

      order.term_of_invoice.each do |index, toi|
        next unless %w[0 1].include?(index)

        term  = toi['term']
        days  = toi['days']
        type  = toi['type'] if type.blank?
        value = toi['value']

        next if value.blank? || term.blank? || days.blank?

        top = convert_toi_to_top(term, days)

        if top.blank?
          puts "TOP Not Found for #{term}, #{days}"
          next
        end

        puts "Created #{top.name} - #{value}: #{type}"

        # insert into order term
        order_term = order.order_terms.new
        order_term.term_id = top.id
        order_term.name = top.name
        order_term.baseline_date = top.baseline_date
        order_term.baseline_due = top.baseline_due
        order_term.calculation = type
        order_term.value = value
        order_term.save
      end
    end

    def term_cia
      Finance::Term.find_by(type: 'CustomerTerm', code: 'cia')
    end

    def term_days(days)
      # puts "#{days}"
      Finance::Term.find_by(type: 'CustomerTerm', code: "#{days}d")
    end

    def convert_toi_to_top(term, days)
      if term == 'before_production'
        term_cia
      elsif term == 'before_delivery'
        term_days(7)
      elsif term == 'after_order_completed'
        days = 7 if days.to_i == 1
        days = 15 if days.to_i == 14
        term_days(days)
      end
    end
  end
end
