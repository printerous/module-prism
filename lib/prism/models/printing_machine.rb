# == Schema Information
#
# Table name: printing_machines
#
#  id             :bigint(8)        not null, primary key
#  type           :string
#  code           :string
#  name           :string
#  properties     :jsonb
#  deleted_at     :datetime
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  capacity_size  :string
#  operating_size :string
#  size_unit      :string
#

module Prism
  class PrintingMachine < PrismModel
    acts_as_paranoid

    has_many :printing_machine_papers
    has_many :printing_papers, through: :printing_machine_papers
    has_many :partner_machines

    accepts_nested_attributes_for :printing_machine_papers, allow_destroy: true
    self.inheritance_column = nil

    TYPES = {
      'PrintingMachineDigital' => 'Digital',
      'PrintingMachineDigitalEco' => 'Digital Eco',
      'PrintingMachineOffset' => 'Offset',
      'PrintingMachineLargeFormat' => 'Large Format',
      'PrintingMachineCorrugated' => 'Corrugated'
    }

    scope :digitals, -> { where type: 'PrintingMachineDigital' }
    scope :digital_ecos, -> { where type: 'PrintingMachineDigitalEco' }
    scope :offsets, -> { where type: 'PrintingMachineOffset' }
    scope :large_formats, -> { where type: 'PrintingMachineLargeFormat' }
    scope :corrugateds, -> { where type: 'PrintingMachineCorrugated' }

    def self.options
      all.collect { |o| [o.name, o.id] }
    end

    def self.type_options
      TYPES.map { |k, v| [v, k] }
    end

    def self.search(params = {})
      params = {} if params.blank?

      by_query(params[:query])
    end

    scope :by_query, ->(query) {
      return where(nil) if query.blank?

      where('printing_machines.code ILIKE :query
            OR printing_machines.name ILIKE :query',
            query: "%#{ query }%")
    }
  end

end
