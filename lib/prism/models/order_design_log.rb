# frozen_string_literal: true
# == Schema Information
#
# Table name: order_design_logs
#
#  id                    :bigint(8)        not null, primary key
#  order_item_id         :bigint(8)
#  title                 :string
#  file_reference        :string
#  organization_asset_id :integer
#  design                :string
#  deleted_at            :datetime
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  user_id               :bigint(8)
#  time                  :datetime
#

module Prism
  class OrderDesignLog < PrismModel
    acts_as_paranoid

    belongs_to :user, optional: true
    belongs_to :order_item, optional: true
  end
end
