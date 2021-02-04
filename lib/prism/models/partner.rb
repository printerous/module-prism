module Prism
  class Partner < PrismModel
    acts_as_paranoid

    enum status: %i[active inactive banned]
  end
end
