# == Schema Information
#
# Table name: printing_machine_papers
#
#  id                  :bigint(8)        not null, primary key
#  printing_machine_id :bigint(8)
#  printing_paper_id   :bigint(8)
#  deleted_at          :datetime
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#

module Prism
  class PrintingMachinePaper < PrismModel
    acts_as_paranoid

    belongs_to :printing_machine
    belongs_to :printing_paper
  end
end
