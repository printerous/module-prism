# frozen_string_literal: true

# == Schema Information
#
# Table name: component_papers
#
#  id                :bigint(8)        not null, primary key
#  component_id      :bigint(8)
#  printing_paper_id :bigint(8)
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#


module Prism
  class ComponentPaper < PrismModel
    belongs_to :component
    belongs_to :printing_paper
  end
end
