# == Schema Information
#
# Table name: invoice_logs
#
#  id          :bigint(8)        not null, primary key
#  invoice_id  :bigint(8)
#  user_id     :bigint(8)
#  status      :string
#  notes       :string
#  time        :datetime
#  data        :jsonb
#  deleted_at  :datetime
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  description :text
#  action      :string
#
module Prism
  class InvoiceLog < PrismModel
    acts_as_paranoid

    belongs_to :invoice
    belongs_to :user, optional: true

    def user_name
      return 'System' if user.blank?

      user.name
    end
  end
end
