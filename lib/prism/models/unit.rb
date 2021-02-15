# frozen_string_literal: true

# == Schema Information
#
# Table name: units
#
#  id         :bigint(8)        not null, primary key
#  code       :string
#  name       :string
#  deleted_at :datetime
#  created_at :datetime         not null
#  updated_at :datetime         not null
#


module Prism
  class Unit < PrismModel
    def self.options
      all.order(:name).collect { |o| [o.name, o.code] }
  end

    def self.budget_options
      all.order(:name).collect { |o| ["per #{o.name}", o.code] }
    end
  end
end
