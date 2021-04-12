# == Schema Information
#
# Table name: invoice_payments
#
#  id           :bigint(8)        not null, primary key
#  invoice_id   :bigint(8)
#  user_id      :bigint(8)
#  payment_date :datetime
#  price        :decimal(12, 2)
#  status       :integer
#  deleted_at   :datetime
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#
module Prism
  class InvoicePayment < PrismModel
    acts_as_paranoid

    belongs_to :invoice
    belongs_to :user

    enum status: %i[waiting paid cancelled]
  end
end
