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
  class OrganizationAsset < PrismModel
    acts_as_paranoid

    belongs_to :organization
    belongs_to :parent, class_name: 'Prism::OrganizationAsset', foreign_key: 'parent_id', optional: true

    mount_uploader :file, OrganizationAssetUploader
  end
end
