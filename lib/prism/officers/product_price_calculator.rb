# frozen_string_literal: true

module Prism
  class ProductPriceCalculator
    CALCULATOR = {
      digital_calculator: Prism::Calculator::DigitalCalculator,
      digital_eco_calculator: Prism::Calculator::DigitalEcoCalculator,
      offset_calculator: Prism::Calculator::OffsetCalculator,
      large_format_calculator: Prism::Calculator::LargeFormatCalculator,
      corrugated_calculator: Prism::Calculator::CorrugatedCalculator
    }.with_indifferent_access

    attr_reader :product, :product_type, :partner_ids, :partners, :options
    attr_reader :results

    # options:
    # - minimum_quantity
    # - maximum_quantity
    # - calculators: [ 'digital_calculator', 'offset_calculator', 'large_format_calculator' ]
    # - custom_size: {}

    def initialize(product_id, partner_ids, options)
      @product      = Prism::Product.find product_id
      @product_type = product.product_type

      @partner_ids = partner_ids || [Prism::PartnerPrinting.printerous.id]
      @partners    = Partner.where(id: partner_ids)
      @options     = options
      @results     = []
      @errors      = []
    end

    def calculate
      spec_id = Calculator::Website::SpecIdMapper.new(product.spec_id).normalize

      options[:calculators].each do |calc_name|
        calculator = CALCULATOR[calc_name].new(
          product_type_id: product_type.id,
          quantity: options[:minimum_quantity],
          partner_id: partner_ids,
          spec: spec_id,
          size: options[:custom_size]
        )

        calculator.calculate
        price_results = calculator.prices&.sort! { |a, b| [b[:total]] <=> [a[:total]] }
        price_results.each do |result|
          calculator_result = save_calculator_result(calculator, result)
          product_price     = save_product_price(calculator_result)

          @results << product_price.attributes.merge(calculator: calc_name)
        end

        @errors += calculator.errors
      end

      @results
    end

    def errors
      @errors.flatten.compact.uniq
    end

    private

    def save_calculator_result(calculator, result)
      cr = Prism::CalculatorResult.find_or_initialize_by(
        partner_id: result[:partner].id,
        calculator: calculator.class.to_s,
        spec_id: calculator._spec,
        quantity: options[:minimum_quantity]
      )

      cr.spec        = calculator.spec
      cr.price       = result[:price]
      cr.working_day = hour_to_day(result[:hours] || 1)
      cr.data        = result
      cr.save!

      cr
    end

    def save_product_price(calculator_result)
      product_price = ProductPrice.find_or_initialize_by(
        product_id: product.id,
        partner_id: calculator_result.partner_id,
        quantity: calculator_result.quantity,
        source_type: calculator_result.class.to_s
      )

      product_price.source_id    = calculator_result.id
      product_price.quantity_max = options[:maximum_quantity] || calculator_result.quantity
      product_price.unit         = nil
      product_price.working_day  = calculator_result.working_day
      product_price.price        = calculator_result.price
      product_price.expired_at   = nil

      references = product_price.references || []
      references += [options[:references]].flatten.uniq.compact

      product_price.references = references.uniq
      product_price.save!

      product_price
    end

    def hour_to_day(hour, office_hour = 8)
      return 0 if hour <= 6 || hour.infinite?

      (hour / office_hour.to_f).ceil
    end
  end
end
