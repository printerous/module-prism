# frozen_string_literal: true

module Prism
  class EmailingOfficer
    require 'net/http'
    attr_reader :user, :notification_type

    def initialize(user, type)
      @user              = user
      @notification_type = type
    end

    def perform
      response = get(endpoint, data)
      response_body = JSON.parse(response.body, object_class: OpenStruct)
      response_body&.data
    end

    private

    def endpoint
      "#{ENV.fetch('CMS_HOST_URL')}/api/mailing/#{notification_slug}"
    end

    def data
      { uid: user.uid }
    end

    def notification_slug
      case notification_type
      when :reset_password_instructions
        'forgot-password'
      when :password_change
        'password-changed'
      when :confirmation_instructions
        'confirmation'
      when :welcome
        'welcome'
      end
    end

    def get(url, data)
      uri = URI(url)
      uri.query = URI.encode_www_form(data)

      Net::HTTP.get_response(uri)
    end
  end
end