# == Schema Information
#
# Table name: partner_machines
#
#  id                    :bigint(8)        not null, primary key
#  partner_id            :bigint(8)
#  printing_machine_id   :bigint(8)
#  deleted_at            :datetime
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  activated_at          :datetime
#  deactivated_at        :datetime
#  activation_changed_by :bigint(8)
#

module Prism
  class PartnerMachine < PrismModel
    acts_as_paranoid

    belongs_to :partner
    belongs_to :printing_machine
    belongs_to :activation_actor, class_name: 'User', foreign_key: :activation_changed_by, optional: true

    def activate!(user)
      update(activated_at: Time.current, deactivated_at: nil, activation_actor: user)
    end

    def deactivate!(user)
      update(deactivated_at: Time.current, activated_at: nil, activation_actor: user)
    end

    def is_active?
      activated_at.present?
    end
  end

end
