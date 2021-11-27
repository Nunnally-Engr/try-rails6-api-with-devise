module V1
  class RegistrationsController < DeviseTokenAuth::RegistrationsController
    private
      def sign_up_params
        params.permit(:email, :password, :password_confirmation, :name)
      end
  end
end
