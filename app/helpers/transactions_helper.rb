module TransactionsHelper
  def transaction_modal(transaction)
    render 'transactions/partials/show', transaction: transaction
  end

  def show_transaction(transaction)
    link_to transaction.identifier, '#' << transaction.identifier.to_s
  end
end
