# == Schema Information
#
# Table name: order_website_timelines
#
#  id            :bigint           not null, primary key
#  order_item_id :bigint
#  status        :string
#  title         :string
#  description   :string
#  time          :datetime
#  deleted_at    :datetime
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#

module Prism
  class OrderWebsiteTimeline < PrismModel
    acts_as_paranoid

  end
end