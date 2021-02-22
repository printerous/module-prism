# == Schema Information
#
# Table name: main_addresses
#
#  id                      :bigint           not null, primary key
#  user_id                 :integer
#  organization_address_id :integer
#

module Prism
  class MainAddress < PrismModel
    belongs_to :user
    belongs_to :organization_address
  end
end
