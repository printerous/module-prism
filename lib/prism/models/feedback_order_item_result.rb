# == Schema Information
#
# Table name: feedback_order_item_results
#
#  id            :bigint(8)        not null, primary key
#  order_item_id :bigint(8)
#  user_id       :bigint(8)
#  partner_id    :bigint(8)
#  results       :jsonb
#  notes         :text
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  order_id      :integer
#  deleted_at    :datetime
#

module Prism
  class FeedbackOrderItemResult < PrismModel
    acts_as_paranoid

    belongs_to :user
    belongs_to :partner

    def product_score
      results['product']&.to_f
    end

    def packing_score
      results['package']&.to_f
    end
  end
end
