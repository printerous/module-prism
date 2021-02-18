# == Schema Information
#
# Table name: order_items
#
#  id                     :bigint(8)        not null, primary key
#  order_id               :bigint(8)
#  type                   :string
#  number                 :string
#  title                  :string
#  product_type_id        :bigint(8)
#  shipping_address_id    :integer
#  shipping               :jsonb
#  shipping_courier_id    :integer
#  spec                   :jsonb
#  file_preview           :jsonb
#  file_proof             :string
#  file_artwork           :string
#  quantity               :float            default(0.0)
#  unit                   :string
#  price                  :decimal(12, 3)   default(0.0)
#  discount               :decimal(12, 2)   default(0.0)
#  tax_policy             :integer
#  tax                    :decimal(12, 2)   default(0.0)
#  shipping_fee           :decimal(12, 2)   default(0.0)
#  subtotal               :decimal(12, 2)   default(0.0)
#  grand_total            :decimal(12, 2)   default(0.0)
#  finish_time            :datetime
#  delivery_time          :datetime
#  data                   :jsonb
#  config                 :jsonb
#  status                 :integer
#  deleted_at             :datetime
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  integration            :jsonb
#  organization_asset_id  :integer          default(0)
#  file_reference         :string
#  billing_address_id     :integer
#  billing                :jsonb
#  original_files         :jsonb
#  device_source          :string
#  user_agent             :string
#  product_id             :integer
#  flag                   :string
#  cuanki_product_type_id :integer
#  pic_id                 :integer
#  pic_support_id         :integer
#

module Prism
  class OrderItem < PrismModel
    acts_as_paranoid

    belongs_to :order, -> { with_deleted }
  end
end
