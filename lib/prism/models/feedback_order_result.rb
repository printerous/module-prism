# == Schema Information
#
# Table name: feedback_order_results
#
#  id                :bigint(8)        not null, primary key
#  order_id          :bigint(8)
#  user_id           :bigint(8)
#  score             :integer
#  reason_ids        :jsonb
#  notes             :text
#  last_submitted_at :datetime
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  device_source     :jsonb
#  accessed_at       :datetime
#  source            :string           default("email")
#  deleted_at        :datetime
#

module Prism
  class FeedbackOrderResult < PrismModel
    acts_as_paranoid
    has_many :feedback_order_result_logs, dependent: :destroy

    belongs_to :order
    belongs_to :user
  end
end
