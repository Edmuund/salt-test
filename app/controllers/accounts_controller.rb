class AccountsController < ApplicationController
  def index
    login = current_user.logins.find(params[:login_id])
    @accounts = login.accounts.order('identifier desc')
  end
end
