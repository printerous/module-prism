# frozen_string_literal: true
require File.dirname(__FILE__) + '/offset/time/time_formula.rb'

module Prism
  class Calculator::ProductionTimeFormula < Prism::Calculator::Offset::Time::TimeFormula
    attr_accessor :errors, :results

    @errors = []
    @results = []

    DATA = [
      {
        name: 'PrintingTime',
        dependencies: []
      },
      {
        name: 'LaminationPreparationTime',
        dependencies: [],
        type: 'finishing',
        spec_keys: Prism::SpecKey.where(code: %w[lamination lamination_b]).collect(&:id)
      },
      {
        name: 'LaminationTime',
        dependencies: %w[PrintingTime LaminationPreparationTime],
        type: 'finishing',
        spec_keys: Prism::SpecKey.where(code: %w[lamination lamination_b]).collect(&:id)
      },
      {
        name: 'PondPreparationTime',
        dependencies: [],
        type: 'finishing',
        spec_keys: Prism::SpecKey.where(code: ['cutting']).collect(&:id)
      },
      {
        name: 'PondTime',
        dependencies: %w[PondPreparationTime PrintingTime LaminationTime],
        type: 'finishing',
        spec_keys: Prism::SpecKey.where(code: ['cutting']).collect(&:id)
      },
      {
        name: 'FoldingPreparationTime',
        dependencies: [],
        type: 'finishing',
        spec_keys: Prism::SpecKey.where(code: ['folding']).collect(&:id)
      },
      {
        name: 'FoldingTime',
        dependencies: %w[PrintingTime FoldingPreparationTime PondTime LaminationTime],
        type: 'finishing',
        spec_keys: Prism::SpecKey.where(code: ['folding']).collect(&:id)
      }
    ].freeze

    def calculate
      total_time = []
      self.class::DATA.each do |data|
        # Check is finishing exists on spec
        next if data[:type] == 'finishing' && (spec_keys & data[:spec_keys]).empty?

        total_time.push(memoize(data, @results).to_i)
      end
      # if product_data already removed because there is some component not available
      return -1 if product_data.blank?

      product_data[:production_time] = total_time.max

      total_time.max
    end

    def spec_keys
      @product._spec.reject { |_k, v| v.blank? }.keys.collect(&:to_i)
    end

    def memoize(data, _results = [])
      if begin
            @results[data[:name]]
         rescue StandardError
           false
          end
        @results[data[:name]]
      else
        # calculate self
        Rails.logger.info "=== Calculate #{data[:name]} ==="
        calculation_formula = calculation(data)
        self_time = calculation_formula.perform

        @errors += calculation_formula.errors if calculation_formula.errors.present?

        dependencies_times = []
        # calculate dependencies
        Rails.logger.info "--- Calculate dependencies #{data[:dependencies]} ---"
        Rails.logger.info "## #{@results} ##"
        data[:dependencies].each do |depend|
          value = if begin
                        @results[depend]
                     rescue StandardError
                       false
                      end
                    @results[depend]
                  else
                    Rails.logger.info "--- DEPENDENCIES #{depend} ---"
                    calculation_formula = calculation(data)
                    @errors += calculation_formula.errors if calculation_formula.errors.present?
                    time = calculation_formula.perform
                    @results[depend] = time
                    time
          end
          dependencies_times.push(value.to_f)
        end

        total = dependencies_times.max.to_f + self_time.to_f
        @results[data[:name]] = total

        Rails.logger.info "==== TIME SELF : #{data[:name]} = #{self_time.to_f} ===="
        Rails.logger.info "==== TIME DEPENDENCIES: #{@results} ===="
        total
      end
    end

    def calculation(data)
      formula = "Prism::Calculator::Offset::Time::#{data[:name]}Formula".constantize.new(
        product: @product,
        partner: @partner,
        paper: @paper,
        machine: @machine,
        total_material_quantity: @total_material_quantity
      )

      formula
    end
  end
end
