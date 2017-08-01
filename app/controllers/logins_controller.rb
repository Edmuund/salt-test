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
    return if request_failed?('create')
    params[:login].merge! @response
    save
  end

  def refresh
    @response = SALT_LOGIN.new(current_user, existing_login: @login, secret: @login.secret).refresh
    return if request_failed?('refresh')
    params[:login] = @response
    @login.update!(login_params)
    redirect_to root_path, alert: "Login ##{params[:id]} was refreshed."
  end

  def reconnect
    @disable_nav = true
  end

  def update
    @disable_nav    = true
    @body_full      = true
    @disable_alerts = true
    @response = SALT_LOGIN.new(current_user,
                               params: params,
                               existing_login: @login,
                               secret: @login.secret).reconnect
    return if request_failed?('update')
    params[:login].merge! @response
    update_login
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

  def request_failed?(action)
    if @response.is_a? Hash
      false
    else
      error = @response
      case action
      when 'create'
        redirect_to new_login_path, alert: error
      when 'update'
        redirect_to reconnect_login_path(params[:id]), alert: error
      else
        redirect_to root_path, alert: error
      end
      true
    end
  end

  def save
    @login = current_user.logins.new(login_params)
    return if @login.save
    redirect_to new_login_path, alert: @login.errors.full_messages
  end

  def update_login
    return false if @login.update(login_params)
    redirect_to reconnect_login_path(params[:login][:id]), alert: @login.errors.full_messages
  end

  def login_find
    @login = current_user.logins.find(params[:id])
  end

  def login_params
    params.require(:login).permit(:username, :pass, :id, :secret, :provider, :country,
                                  :status, :error, :next_refresh, :created_at, :updated_at,
                                  accounts_attributes: account_params)
  end

  def account_params
    [:id, :identifier, :currency, :name, :nature, :balance, :iban, :cards,
     :swift, :client_name, :account_name, :account_number, :available_amount,
     :credit_limit, :posted, :pending, :created_at, :updated_at,
     transactions_attributes: %i[id identifier category currency amount
                                 description account_balance_snapshot
                                 categorization_confidence made_on mode
                                 duplicated status created_at updated_at]]
  end

  def destroy_login
    if @response.is_a? String
      flash[:alert] = @response
    else
      @login.destroy
      flash[:alert] = "Login with id: ##{params[:id]} was deleted"
    end
  end
end