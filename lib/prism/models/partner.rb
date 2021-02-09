module Prism
  class Partner < PrismModel
    acts_as_paranoid

    has_many :partner_machines
    has_many :printing_machines, through: :partner_machines

    has_many :active_partner_machines, -> { where(deactivated_at: nil).where('activated_at IS NOT NULL') }, class_name: 'PartnerMachine', foreign_key: :partner_id
    has_many :active_printing_machines, through: :active_partner_machines, source: :printing_machine

    enum status: %i[active inactive banned]
  end
end
