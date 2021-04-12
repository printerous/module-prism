# == Schema Information
#
# Table name: invoice_versions
#
#  id          :bigint(8)        not null, primary key
#  invoice_id  :bigint(8)
#  revision_id :integer
#  version     :integer
#  user_id     :bigint(8)
#  description :string
#  deleted_at  :datetime
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#

module Prism
  class InvoiceVersion < PrismModel
    belongs_to :invoice_base, class_name: 'Invoice', foreign_key: :revision_id
    belongs_to :invoice
    belongs_to :user
  end
end
