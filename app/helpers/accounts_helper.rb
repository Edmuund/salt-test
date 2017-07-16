module AccountsHelper
  def account_modal(account)
    render 'accounts/partials/show', account: account
  end

  def show_account(account)
    link_to account.name, '#' << account.identifier.to_s
  end

  def index_transactions(account)
    return 0 if account.posted == '0'
    link_to account.transactions.count,
            login_account_transactions_path(params[:login_id], account.identifier)
  end

  def cards(cards)
    cards.to_s.delete('[]""')
  end

  def account_filter(name)
    '***' << name.last(3)
  end
end
