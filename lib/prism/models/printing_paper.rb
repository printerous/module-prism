# frozen_string_literal: true

# == Schema Information
#
# Table name: printing_papers
#
#  id             :bigint(8)        not null, primary key
#  code           :string
#  name           :string
#  width          :float
#  length         :float
#  deleted_at     :datetime
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  paper_base_id  :integer
#  activated_at   :datetime
#  deactivated_at :datetime
#


module Prism
  class PrintingPaper < PrismModel
    acts_as_paranoid

    has_many   :printing_machine_papers
    has_many   :printing_machines, through: :printing_machine_papers

    belongs_to :base_paper, class_name: 'PrintingPaper', foreign_key: 'paper_base_id', optional: true

    scope :base, -> { where(paper_base_id: nil) }
    scope :large_formats, -> { where('code ILIKE ?', 'lf%') }

    def active?
      !active_at.nil? && inactive_at.nil?
    end

    def deactive?
      active_at.nil? && !inactive_at.nil?
    end

    def activate!
      update(active_at: Time.current, inactive_at: nil)
    end

    def deactivate!
      update(active_at: nil, inactive_at: Time.current)
    end

    def size
      "#{width_in_cm.to_i}x#{length_in_cm.to_i}cm"
    end

    def size_in_m2
      width_in_cm * length_in_cm / 10_000.0
    end

    def width_in_cm
      width / 10
    end

    def length_in_cm
      length / 10
    end

    def weight(gsm)
      size_in_m2 * gsm.to_f / 1000
    end

    def plano
      base_paper || self
    end
  end
end
