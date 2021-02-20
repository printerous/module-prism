module Prism
  class CustomerRegistrationOfficer
    attr_reader :params, :user

    def initialize(params)
      @params = params
      @user   = build_user
    end

    def perform
      ActiveRecord::Base.transaction do
        # personal < organization
        @personal = Prism::Personal.create(
          name: user.name,
          anniversary: user.dob,
          phone: user.phone
        )

        @user.person = build_person
        @user.person.personal = @personal
        @user.person.organization_member.phone = @user.phone
        @user.save!
      rescue ActiveRecord::RecordInvalid
        raise ActiveRecord::Rollback

        false
      end
    end

    private

    def build_user
      uid = SecureRandom.uuid

      Prism::UserCustomer.new(
        name: params[:name],
        email: params[:email],
        phone: params[:phone],
        gender: params[:gender],
        password: params[:password],
        password_confirmation: params[:password_confirmation],
        uid: uid
      )
    end

    def build_person
      person = Person.find_or_initialize_by(email: user.email)
      person.name          = user.name
      person.phone         = user.phone
      person.gender        = user.gender
      person.date_of_birth = user.dob
      person.data          = []
      person.integration   = []

      person
    end
  end
end
