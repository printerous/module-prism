require File.dirname(__FILE__) + '/partner.rb'

module Prism
  class PartnerPrinting < Prism::Partner
    acts_as_paranoid

    def self.printerous
      PartnerPrinting.find_by("properties ? 'is_printerous'") ||
        PartnerPrinting.find_by(id: 1)
    end
  end
end
