# frozen_string_literal: true

# == Schema Information
#
# Table name: order_item_prices
#
#  id            :bigint(8)        not null, primary key
#  order_item_id :bigint(8)
#  source_type   :string
#  source_id     :integer
#  partner_id    :bigint(8)
#  price         :decimal(12, 2)
#  working_day   :integer
#  rank          :integer
#  status        :integer
#  respond_time  :datetime
#  respond_by    :integer
#  deleted_at    :datetime
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  notes         :text
#  integration   :jsonb
#  expired_at    :datetime
#  flag          :string
#  data          :jsonb
#

module Prism
  class OrderItemPrice < PrismModel
    acts_as_paranoid

    belongs_to :order_item

    enum status: %i[waiting sent rejected approved skipped cancelled]

    scope :waiting, -> { where(status: Prism::OrderItemPrice.statuses[:waiting]) }
    scope :auto_distribution, -> { where(flag: 'auto') }
    scope :active_distribution, -> { where("data ->> 'distribution' = ?", 'active') }
    scope :closed_distribution, -> { where("data ->> 'distribution' = ?", 'closed') }
  end
end
