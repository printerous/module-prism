# frozen_string_literal: true

module Prism
  class PriceUploader < CarrierWave::Uploader::Base
    if Rails.env.development? || Rails.env.test?
      storage :file
    else
      storage :fog
    end

    # Override the directory where uploaded files will be stored.
    # This is a sensible default for uploaders that are meant to be mounted:
    def store_dir
      "#{Rails.env}/uploads/partner_variant_price_file/#{mounted_as}/#{model.id}"
    end

    # Provide a default URL as a default if there hasn't been a file uploaded:
    # def default_url(*args)
    #   # For Rails 3.1+ asset pipeline compatibility:
    #   # ActionController::Base.helpers.asset_path("fallback/" + [version_name, "default.png"].compact.join('_'))
    #
    #   "/images/fallback/" + [version_name, "default.png"].compact.join('_')
    # end

    # Override the filename of the uploaded files:
    # Avoid using model.id or version_name here, see uploader/store.rb for details.
    # def filename
    #   "something.jpg" if original_filename
    # end

    def file_name
      File.basename(path) if original_filename.nil?
    end

    def full_url
      return url if url =~ /^http/

      Rails.application.config.default_host_url + url
    end
  end
end
