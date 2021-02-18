# == Schema Information
#
# Table name: feedback_order_result_logs
#
#  id                       :bigint(8)        not null, primary key
#  feedback_order_result_id :bigint(8)
#  accessed_from            :string
#  device                   :string
#  created_at               :datetime         not null
#  updated_at               :datetime         not null
#  action_code              :string
#  deleted_at               :datetime
#

module Prism
  class FeedbackOrderResultLog < PrismModel
    acts_as_paranoid

    belongs_to :feedback_order_result
  end
end
