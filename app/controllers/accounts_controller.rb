class AccountsController < ApplicationController
  def index
    @login = current_user.logins.find(params[:login_id])
    @accounts = @login.accounts.includes(:transactions).order('created_at desc')
  end
end
