# frozen_string_literal: true

module Prism
  class OrganizationAssetUploader < FileUploader
    def store_dir
      "#{Rails.env}/uploads/organization_asset/#{mounted_as}/#{model.id}"
    end
  end
end
