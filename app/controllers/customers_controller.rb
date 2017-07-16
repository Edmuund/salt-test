class CustomersController < Devise::RegistrationsController
  require 'api_request'
  SALT_CUSTOMER = ApiRequest::Resource::Customer

  def create
    @response = SALT_CUSTOMER.new(params[:user][:email]).create
    return if request_failed?
    super
  end

  private

  def request_failed?
    if @response.is_a? Hash
      params[:user].merge! @response
      false
    else
      error = @response
      redirect_to new_user_registration_path, alert: error
      true
    end
  end

  def sign_up_params
    params.require(:user).permit(:email, :password, :password_confirmation,
                                 :customer_id, :customer_secret)
  end
end