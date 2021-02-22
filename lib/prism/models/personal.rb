# == Schema Information
#
# Table name: organizations
#
#  id                 :bigint(8)        not null, primary key
#  parent_id          :integer
#  type               :string
#  name               :string
#  website            :string
#  anniversary        :date
#  phone              :string
#  status             :integer
#  deleted_at         :datetime
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  profile_completion :integer
#  lead_source_id     :integer
#  data               :jsonb
#  code               :string
#  integration        :jsonb
#  is_pro             :integer
#

require File.dirname(__FILE__) + '/organization.rb'

module Prism
  class Personal < Organization
    def person
      people.order(id: :asc).first
    end
  end
end
