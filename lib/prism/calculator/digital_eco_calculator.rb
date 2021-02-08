module Prism
  class Calculator::DigitalEcoCalculator < Prism::Calculator::DigitalCalculator
    def initialize(params)
      super(params)

      @paper_code    = 'a3toner320x450'
      @printing_type = 'digital_eco'
    end
  end

end
