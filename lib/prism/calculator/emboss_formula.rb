# frozen_string_literal: true

module Prism
  class Calculator::EmbossFormula < Calculator::PostPressFormula
    COMPONENT_CODE = 'EMBOSS'

    def price_name
      'emboss_price'
    end

    def calculate
      is_none = @product.spec[:emboss]&.to_s&.to_s&.upcase&.strip == 'NONE'
      return 0 if @product.spec[:emboss].blank? || is_none

      super
    end
  end
end
