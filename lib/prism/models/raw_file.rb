# frozen_string_literal: true

# == Schema Information
#
# Table name: organization_assets
#
#  id              :bigint(8)        not null, primary key
#  organization_id :bigint(8)
#  type            :string
#  name            :string
#  file            :string
#  deleted_at      :datetime
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  parent_id       :integer          default(0)
#  version         :integer          default(1)
#

module Prism
  class RawFile < OrganizationAsset
  end
end
