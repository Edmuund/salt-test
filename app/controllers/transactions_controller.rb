class TransactionsController < ApplicationController
  def index
    account = Account.find_by(identifier: params[:account_id])
    @transactions = account.transactions.order('identifier desc')
  end
end
