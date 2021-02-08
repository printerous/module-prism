module Prism
  class SpecKey < PrismModel
    acts_as_paranoid

    def is_direct?
      properties['is_direct']&.to_i == 1
    end
  end
end
