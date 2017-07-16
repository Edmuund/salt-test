class LoginsController < ApplicationController
  before_action :login_find, only: %i[refresh reconnect update destroy]
  require 'api_request'
  SALT_LOGIN = ApiRequest::Resource::Login

  def index
    @logins = current_user.logins.order('created_at desc')
  end

  def new
    @disable_nav = true
    @login = current_user.logins.new
  end

  def create
    @disable_nav    = true
    @body_full      = true
    @disable_alerts = true
    return if duplicated_credentials?
    @response = SALT_LOGIN.new(current_user, params: params).create
    return if request_failed?
    params[:login].merge! @response
    @login = current_user.logins.new(login_params).save
    save_failed?
  end

  def refresh
    @response = SALT_LOGIN.new(current_user, existing_login: @login, secret: @login.secret).refresh
    return if request_failed?
    params[:login] = @response
    @login = @login.update(login_params)
    return if refresh_failed?
    redirect_to root_path, alert: "Login ##{params[:id]} was refreshed."
  end

  def reconnect
    @disable_nav = true
  end

  def update
    @disable_nav    = true
    @body_full      = true
    @disable_alerts = true
    return if different_username?
    @response = SALT_LOGIN.new(current_user,
                               params: params,
                               existing_login: @login,
                               secret: @login.secret).reconnect
    return if reconnect_failed?
    params[:login].merge! @response
    @login = @login.update(login_params)
    update_failed?
  end

  def destroy
    @response = SALT_LOGIN.new(current_user, existing_login: @login).destroy
    destroy_login
    redirect_to root_path
  end

  def stage
    respond_to do |format|
      format.json { render json: { stage: SALT_LOGIN.stage } }
    end
  end

  private

  def duplicated_credentials?
    if Login.exists?(username: params[:login][:username], provider: params[:login][:bank])
      redirect_to new_login_path, alert: 'A login with these credentials already exists.'
      true
    else
      false
    end
  end

  def request_failed?
    if @response.is_a? Hash
      false
    else
      error = @response
      redirect_to new_login_path, alert: error
      true
    end
  end

  def refresh_failed?
    if @response.is_a? Hash
      false
    else
      error = @response
      redirect_to root_path, alert: error
      true
    end
  end

  def reconnect_failed?
    if @response.is_a? Hash
      false
    else
      error = @response
      redirect_to reconnect_login_path(params[:id]), alert: error
      true
    end
  end

  def save_failed?
    return if @login
    redirect_to new_login_path, alert: @login.errors
  end

  def update_failed?
    return false if @login
    redirect_to reconnect_login_path(params[:login][:id]), alert: @login.errors
  end

  def different_username?
    return false if params[:login][:username] == @login.username
    redirect_to reconnect_login_path(params[:id]), alert: 'Username should not be changed.'
    true
  end

  def login_find
    @login = current_user.logins.find(params[:id])
  end

  def login_params
    params.require(:login).permit(:username, :pass, :id, :secret, :provider, :country,
                                  :status, :error, :next_refresh, :created_at, :updated_at,
                                  accounts_attributes: permitted_accounts_attributes)
  end

  def permitted_accounts_attributes
    [:id, :identifier, :currency, :name, :nature, :balance, :iban, :cards,
     :swift, :client_name, :account_name, :account_number, :available_amount,
     :credit_limit, :posted, :pending, :created_at, :updated_at,
     transactions_attributes: %i[id identifier category currency amount
                                 description account_balance_snapshot
                                 categorization_confidence made_on mode
                                 duplicated status created_at updated_at]]
  end

  def destroy_login
    if (@response.is_a? String) && @response.include?('limit')
      flash[:alert] = @response
    else
      @login.destroy
      flash[:alert] = "Login with id: #{params[:id]} was deleted"
    end
  end
end