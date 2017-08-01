require 'rails_helper'

RSpec.describe TransactionsController, type: :controller do
  it 'renders index' do
    user = User.create(email: 'test@mail.com', password: 'password')
    sign_in(user)
    login = user.logins.create(username: 'first',
                               accounts_attributes: [{ identifier: 123,
                                                       transactions_attributes: [{ identifier: 123 }] }])
    account = login.accounts.first
    get :index, params: { login_id: login.id, account_id: account.identifier }
    expect(assigns(:account)).to eq account
    expect(assigns(:transactions)).to eq account.transactions
    expect(response).to render_template :index
  end
end
