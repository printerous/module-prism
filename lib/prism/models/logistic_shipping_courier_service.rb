# == Schema Information
#
# Table name: logistic_shipping_courier_services
#
#  id                                       :bigint(8)        not null, primary key
#  logistic_shipping_courier_id             :bigint(8)
#  code                                     :string
#  name                                     :string
#  description                              :string
#  deleted_at                               :datetime
#  created_at                               :datetime         not null
#  updated_at                               :datetime         not null
#  logistic_shipping_courier_integration_id :bigint(8)
#

module Prism
  class LogisticShippingCourierService < PrismModel
    acts_as_paranoid

    belongs_to :logistic_shipping_courier
  end
end
