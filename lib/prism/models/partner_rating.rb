# frozen_string_literal: true

# == Schema Information
#
# Table name: partner_ratings
#
#  id         :bigint(8)        not null, primary key
#  partner_id :integer
#  period     :string
#  name       :string
#  start_date :date
#  end_date   :date
#  score      :decimal(12, 2)
#  deleted_at :datetime
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  score_user :decimal(12, 2)
#
module Prism
  class PartnerRating < PrismModel
    acts_as_paranoid

    belongs_to :partner, -> { with_deleted }
    has_many :partner_rating_details

    def partner_rating_detail(criteria_id)
      partner_rating_details
        .find_by(partner_rating_criteria_id: criteria_id)
    end

    def calculate_rating
      return nil if weights.zero?

      partner_rating_details.where.not(score: nil).map { |d| d.weight * d.score }.sum / weights
    end

    def weights
      partner_rating_details.where.not(score: nil).sum(&:weight) || 0
    end
  end
end
