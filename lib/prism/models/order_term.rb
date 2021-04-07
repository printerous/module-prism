# == Schema Information
#
# Table name: order_terms
#
#  id            :bigint(8)        not null, primary key
#  quotation_id  :integer
#  term_id       :integer
#  order_id      :integer
#  name          :string
#  baseline_date :string
#  baseline_due  :integer
#  calculation   :string
#  value         :float
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#

module Prism
  class OrderTerm < PrismModel
    belongs_to :order
    belongs_to :quotation, optional: true
    has_many   :order_term_items

    def terms_detail
      Finance::Term.find term_id
    end

    def percentage?
      calculation == 'percentage'
    end

    def amount?
      calculation == 'amount'
    end
  end
end
