module Prism
  class UserAddressOfficer
    attr_reader :user, :params

    def initialize(user, params)
      @user   = user
      @params = params
    end

    def perform
      ActiveRecord::Base.transaction do
        user_address.label       = params[:label]&.strip if params[:label].present?
        user_address.pic_name    = params[:pic_name]&.strip if params[:pic_name].present?
        user_address.pic_phone   = params[:pic_phone]&.strip if params[:pic_phone].present?
        user_address.pic_email   = params[:pic_email]&.strip if params[:pic_email].present?
        user_address.street      = params[:street]&.strip if params[:street].present?
        user_address.district_id = params[:district_id] if params[:district_id].present?
        user_address.zip_code    = params[:zip_code]&.to_s&.strip if params[:zip_code].present?
        user_address.latitude    = params[:latitude] if params[:latitude].present?
        user_address.longitude   = params[:longitude] if params[:longitude].present?

        personal = user.personal
        user_address.organization_id = personal.id

        user_address.save! && save_main_address
      end
    end

    def user_address
      @user_address ||= user.user_addresses.find_by(id: params[:id]) || Prism::OrganizationAddress.new
    end

    private

    def save_main_address
      return true if params[:main].blank? || !params[:main] || !user_address.valid?

      main_address = user.main_address || user.build_main_address
      main_address.organization_address_id = user_address.id
      main_address.save!
    end
  end
end
