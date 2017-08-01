require 'rails_helper'

RSpec.describe AccountsController, type: :controller do
  it 'renders index' do
    user = User.create(email: 'test@mail.com', password: 'password')
    sign_in(user)
    login = user.logins.create(username: 'first', accounts_attributes: [{ identifier: 123 }])
    get :index, params: { login_id: login.id }
    expect(assigns(:login)).to eq login
    expect(assigns(:accounts)).to eq login.accounts
    expect(response).to render_template :index
  end
end
