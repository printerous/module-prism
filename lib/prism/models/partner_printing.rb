require File.dirname(__FILE__) + '/partner.rb'

module Prism
  class PartnerPrinting < Prism::Partner
    acts_as_paranoid
  end
end
