module Prism
  class OmniauthOfficer
    attr_reader :params, :errors, :user, :new_registered

    # params
    # - user_id
    # - data from omniauth (uid, provider, name, email, etc)
    def initialize(params)
      @params         = params
      @user           = Prism::User.find_by(id: params[:user_id])
      @errors         = []
      @new_registered = false
    end

    def perform
      return unless valid?

      # Register
      if user.blank? && social_account.new_record?
        register_user
      end

      if social_account.persisted?
        @user = social_account.user unless social_account.user.blank?
        register_user if social_account.user.blank?
      end

      social_account.user_id   = @user.id # Reconnect
      social_account.email     = registration_params[:email]
      social_account.name      = params[:name]
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

    def register_user
      officer = Prism::CustomerRegistrationOfficer.new(registration_params.merge(confirmed_at: Time.now))
      officer.perform
      @user = officer.user
      @user.save!
      @new_registered = true
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
