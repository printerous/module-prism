# frozen_string_literal: true

# == Schema Information
#
# Table name: logistic_shipping_couriers
#
#  id                 :bigint(8)        not null, primary key
#  code               :string
#  name               :string
#  integration_module :string
#  deleted_at         :datetime
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  properties         :jsonb
#  integration_type   :jsonb
#  logo               :string
#  status             :integer
#
module Prism
  class LogisticShippingCourier < PrismModel
    acts_as_paranoid

    has_many :logistic_shipping_courier_services
  end
end
