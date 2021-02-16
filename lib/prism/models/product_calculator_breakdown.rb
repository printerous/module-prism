# frozen_string_literal: true

# == Schema Information
#
# Table name: product_calculator_breakdowns
#
#  id                    :bigint(8)        not null, primary key
#  product_calculator_id :bigint(8)
#  input_type            :string
#  relation_type         :string
#  relation_id           :integer
#  group                 :string
#  code                  :string
#  name                  :string
#  description           :text
#  formula               :string
#  deleted_at            :datetime
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  position              :integer
#  module_relation_type  :string
#  module_formula        :string
#


module Prism
  class ProductCalculatorBreakdown < PrismModel
    acts_as_paranoid

    belongs_to :product_calculator
    belongs_to :relation, polymorphic: true, optional: true, foreign_type: :module_relation_type
  end
end
