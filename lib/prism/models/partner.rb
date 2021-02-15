module Prism
  class Partner < PrismModel
    acts_as_paranoid

    has_many :partner_machines
    has_many :printing_machines, through: :partner_machines

    has_many :active_partner_machines, -> { where(deactivated_at: nil).where('activated_at IS NOT NULL') }, class_name: 'PartnerMachine', foreign_key: :partner_id
    has_many :active_printing_machines, through: :active_partner_machines, source: :printing_machine

    has_one  :alltime, -> { where(period: 'alltime') }, class_name: 'PartnerRating'
    has_one  :current_mtd, -> { where(period: 'mtd').where(end_date: Date.yesterday) }, class_name: 'PartnerRating'
    has_many :three_months_before, -> { where(period: 'monthly').where(name: (1..3).to_a.map { |i| (Date.today - i.month).strftime('%b %Y') }).order(created_at: 'desc') }, class_name: 'PartnerRating'


    enum status: %i[active inactive banned]
  end
end
