module Prism
  class OmniauthOfficer
    attr_reader :params, :errors, :user

    # params
    # - user_id
    # - data from omniauth (uid, provider, name, email, etc)
    def initialize(params)
      @params = params
      @user   = Prism::User.find_by(id: params[:user_id])
      @errors = []
    end

    def perform
      return unless valid?

      # Register
      if user.blank? && social_account.new_record?
        officer = Prism::CustomerRegistrationOfficer.new(registration_params)
        officer.perform
        @user = officer.user
      end

      if social_account.persisted?
        @user = social_account.user
      end

      social_account.user_id   = @user.id # Reconnect
      social_account.email     = @user.email
      social_account.connected = true
      social_account.save!
    rescue StandardError => e
      @errors << e.message
      false
    end

    def valid?
      validate_user_relation
      validate_provider
      @errors.blank?
    end

    def social_account
      @social_account ||= Prism::SocialAccount.find_or_initialize_by(uid: params[:uid], provider: params[:provider])
    end

    private

    def validate_user_relation
      if user.present? && social_account&.connected && social_account&.user_id != user.id
        @errors << 'This social account is already connected to another user.'
      end
    end

    def validate_provider
      unless ['google_oauth2', 'facebook'].include?(params[:provider])
        @errors << 'Provider are not supported'
      end
    end

    def registration_params
      password = SecureRandom.hex # random password
      email    = params[:email] || social_email

      {
        name: params[:name],
        email: email,
        phone: params[:phone],
        gender: params[:gender],
        password: password,
        password_confirmation: password
      }
    end

    def social_email
      [params[:uid], params[:provider]].join('@').concat('.com')
    end
  end
end
