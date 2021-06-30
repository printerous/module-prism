# == Schema Information
#
# Table name: order_website_statuses
#
#  id            :bigint(8)        not null, primary key
#  status        :string
#  time          :datetime
#  deleted_at    :datetime
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  order_item_id :bigint(8)
#  is_complete   :boolean          default(TRUE)
#

module Prism
  class OrderWebsiteStatus < PrismModel
    acts_as_paranoid

    STATUS = %w[accepted paid on_production on_shipping delivered cancelled expired].freeze

    belongs_to :order_item

    def complete?
      is_complete
    end
  end
end
