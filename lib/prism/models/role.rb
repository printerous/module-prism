# frozen_string_literal: true

module Prism
  class Role < PrismModel
    has_many :users

    def self.sales_roles
      role_id = ENV.fetch('SALES_ROLE_ID', '3,11,12,14').split(/\s*[.,]\s*/)
      where(id: role_id).map(&:code)
    end
  end
end
