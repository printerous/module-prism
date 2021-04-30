# frozen_string_literal: true

module Prism
  class FileUploader < CarrierWave::Uploader::Base
    if Rails.env.development? || Rails.env.test?
      storage :file
    else
      storage :fog
    end

    # Override the directory where uploaded files will be stored.
    # This is a sensible default for uploaders that are meant to be mounted:
    def store_dir
      klass_name = model.class.to_s.split('::').last
      "#{ Rails.env }/uploads/#{ klass_name.underscore }/#{ mounted_as }/#{ model.id }"
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
      return nil if path.nil?

      File.basename(path) if original_filename.nil?
    end

    def full_url
      return url if url =~ /^http/

      ENV['PRISM_API_HOST_URL'] + url
    end
  end
end
