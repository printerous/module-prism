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
  class UserAdmin < User
    def self.sales_options
      sales_users.collect do |user|
        [
          user.name, user.id, {
            'data-showme' => user.active? ? '1' : '0',
            'data-active' => '1'
          }
        ]
      end
    end

    def self.active_sales_options
      sales_users.where(deactivated_at: nil).collect do |user|
        [
          user.name, user.id, {
            'data-showme' => user.active? ? '1' : '0',
            'data-active' => '1'
          }
        ]
      end
    end
  end
end
