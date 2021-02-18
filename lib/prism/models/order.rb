# == Schema Information
#
# Table name: orders
#
#  id                     :bigint(8)        not null, primary key
#  type                   :string
#  source                 :string
#  number                 :string
#  organization_member_id :bigint(8)
#  user_id                :bigint(8)
#  currency_id            :integer
#  tax_policy             :integer
#  tax                    :decimal(12, 2)
#  discount               :decimal(12, 2)
#  shipping_fee           :decimal(12, 2)   default(0.0)
#  subtotal               :decimal(12, 2)   default(0.0)
#  grand_total            :decimal(12, 2)   default(0.0)
#  status                 :integer
#  payment_status         :integer
#  payment_info           :jsonb
#  deleted_at             :datetime
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  data                   :jsonb
#  submitted_date         :datetime
#  integration            :jsonb
#  customer_po_file       :string
#  category               :string           default("sales")
#  po_number              :string
#  sales_id               :integer
#

module Prism
  class Order < PrismModel
    acts_as_paranoid

    belongs_to :user, -> { with_deleted }
    belongs_to :organization_member, -> { with_deleted }
    belongs_to :currency

    has_one :organization, through: :organization_member
  end
end
