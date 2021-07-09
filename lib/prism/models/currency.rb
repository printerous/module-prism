# == Schema Information
#
# Table name: currencies
#
#  id         :bigint(8)        not null, primary key
#  code       :string
#  sign       :string
#  name       :string
#  deleted_at :datetime
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

module Prism
  class Currency < PrismModel
    acts_as_paranoid
  end
end
