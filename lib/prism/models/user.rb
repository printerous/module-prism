# frozen_string_literal: true

# == Schema Information
#
# Table name: users
#
#  id                     :bigint(8)        not null, primary key
#  type                   :string
#  role_id                :bigint(8)
#  name                   :string
#  phone                  :string
#  avatar                 :string
#  birthdate              :string
#  gender                 :integer
#  email                  :string           default(""), not null
#  encrypted_password     :string           default(""), not null
#  reset_password_token   :string
#  reset_password_sent_at :datetime
#  remember_created_at    :datetime
#  sign_in_count          :integer          default(0), not null
#  current_sign_in_at     :datetime
#  last_sign_in_at        :datetime
#  current_sign_in_ip     :inet
#  last_sign_in_ip        :inet
#  deleted_at             :datetime
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  source_type            :string
#  source_id              :integer
#  integration            :jsonb
#  deactivated_at         :datetime
#  data                   :jsonb
#  v3_migrated            :integer
#  authentication_token   :string(30)
#  uid                    :string
#  provider               :string
#  image                  :string
#  confirmation_token     :string
#  confirmed_at           :datetime
#  confirmation_sent_at   :datetime
#  unconfirmed_email      :string
#

module Prism
  class User < PrismModel
    acts_as_paranoid

    belongs_to :role, optional: true

    has_one :person_account, dependent: :destroy
    has_one :person, through: :person_account
    has_one :personal, through: :person
    has_one :personal_member, through: :personal

    has_many :user_addresses, through: :personal, source: :organization_addresses
    has_one  :main_address, dependent: :destroy
    has_one  :default_address, through: :main_address, source: :organization_address

    has_many :user_shipping_addresses, -> { where("organization_addresses.types ? 'shipping' AND organization_addresses.types ->> 'shipping' = '1'") },
                                       through: :personal, source: :organization_addresses
    has_many :user_billing_addresses, -> { where("organization_addresses.types ? 'billing' AND organization_addresses.types ->> 'billing' = '1'") },
                                      through: :personal, source: :organization_addresses

    has_many :people, dependent: :destroy
    has_many :companies, through: :person, source: :companies
    has_many :organization_addresses, through: :companies, source: :organization_addresses

    has_many  :user_messaging_integrations, dependent: :destroy
    has_one   :slack_integration, -> { where(messaging_type: 'slack', revoked_at: nil) }, class_name: 'Prism::UserMessagingIntegration'
    has_many  :authentication_tokens, class_name: 'Prism::AuthenticationToken', as: :resource, dependent: :destroy
    has_many  :social_accounts, dependent: :destroy
    has_many  :orders, foreign_key: :user_id
    has_many  :website_orders, -> { where(type: 'OrderWebsite') }, class_name: 'Prism::Order', foreign_key: :user_id

    # Stark Module Dependencies
    has_many :user_carts, class_name: 'Stark::Cart', dependent: :destroy
    has_one  :active_user_cart, -> { where(checkout_at: nil).order(created_at: :desc) }, class_name: 'Stark::Cart'

    enum gender: %i[female male]

    validates :name, presence: true

    def self.sales_users
      sales_codes = Role.sales_roles
      eager_load(:role)
        .where('roles.code IN (:sales_code)', sales_code: sales_codes)
    end

    def active?
      deactivated_at.blank?
    end

    def slack_channel
      slack_integration&.messaging_id
    end

    def slack_hook_url
      return if slack_integration.blank?

      slack_integration.data['hook_url']
    end

    def ensure_authentication_token
      return if authentication_token.present?

      self.authentication_token = generate_authentication_token
    end

    def generate_authentication_token
      loop do
        token = Devise.friendly_token
        break token unless User.where(authentication_token: token).first
      end
    end

    def generate_authentication_token!
      return true if authentication_token.present?

      self.authentication_token = generate_authentication_token
      save!
    end

    def reset_authentication_token!
      self.authentication_token = nil
      save!
    end

    def dob
      return nil if birthdate.blank? || birthdate == '0000-00-00'

      Date.strptime(birthdate, '%Y-%m-%d')
    end

    def industry
      data['industry']
    end

    def industry=(value)
      data['industry'] = value
    end

    def sso_data
      {
        id: id,
        type: type,
        role_id: role_id,
        email: email,
        name: name,
        phone: phone,
        avatar: avatar,
        birthdate: birthdate,
        gender: gender,
        uid: uid,
        updated_at: updated_at
      }
    end

    def send_devise_notification(notification, *args)
      # devise_mailer.send(notification, self, *args).deliver_later
      # Call API Email
      Prism::EmailingOfficer.new(self, notification).perform
    end

    def send_welcome_notification
      Prism::EmailingOfficer.new(self, :welcome).perform
    end
  end
end
