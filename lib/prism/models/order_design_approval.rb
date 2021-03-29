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
  class OrderDesignApproval < OrderApproval
  end
end
