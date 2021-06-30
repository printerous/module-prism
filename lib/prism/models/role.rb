# frozen_string_literal: true

# == Schema Information
#
# Table name: roles
#
#  id         :bigint(8)        not null, primary key
#  type       :string
#  code       :string
#  name       :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  deleted_at :datetime
#


module Prism
  class Role < PrismModel
    has_many :users

    def self.sales_roles
      role_id = ENV.fetch('SALES_ROLE_ID', '3,11,12,14').split(/\s*[.,]\s*/)
      where(id: role_id).map(&:code)
    end
  end
end
