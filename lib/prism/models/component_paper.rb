# frozen_string_literal: true

module Prism
  class ComponentPaper < PrismModel
    belongs_to :component
    belongs_to :printing_paper
  end
end
