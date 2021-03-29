# frozen_string_literal: true

# == Schema Information
#
# Table name: order_approvals
#
#  id                    :bigint(8)        not null, primary key
#  type                  :string
#  order_item_id         :bigint(8)
#  user_id               :bigint(8)
#  status                :integer
#  notes                 :text
#  time                  :datetime
#  deleted_at            :datetime
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  reason_ids            :jsonb
#  slug                  :string
#  data                  :jsonb
#  attachment            :string
#  integration           :jsonb
#  remaining_accept_time :datetime
#

module Prism
  class OrderApproval < PrismModel
    acts_as_paranoid

    belongs_to :order_item
    belongs_to :user, optional: true

    enum status: %i[rejected approved accepted proceed hold requested]

    def next_step
      return nil if data.blank? || data['next_step'].blank?

      data['next_step']
    end

    def requested?
      ['requested', nil].include?(status)
    end
  end
end
