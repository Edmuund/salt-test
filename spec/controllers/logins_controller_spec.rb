require 'rails_helper'

RSpec.describe LoginsController, type: :controller do
  let(:login)      { assigns(:login) }
  let(:user)       { User.create(email: 'test@mail.com', password: 'password') }
  before(:each)    { sign_in(user) }
  let(:salt_login) { LoginsController::SALT_LOGIN }
  let(:request)    { instance_double(salt_login) }

  describe '#index' do
    it 'selects current user logins' do
      user.logins.create(username: 'first')
      user.logins.create(username: 'second')
      get :index
      expect(assigns(:logins).count).to eq 2
      expect(response).to render_template :index
    end
  end

  describe '#new' do
    it 'generates form for new login' do
      get :new
      expect(response).to render_template :new
    end
  end

  describe '#create' do
    before(:each) do
      allow(salt_login).to receive(:new).and_return request
      allow(request).to receive(:create).and_return id: 999
    end

    it 'redirects if same username and bank' do
      user.logins.create(username: 'username', provider: 'bank')
      post :create, params: { login: { bank: 'bank', username: 'username' } }
      expect(response).to redirect_to new_login_path
      expect(flash[:alert]).to match 'A login with these credentials already exists.'
    end

    it 'does not redirect if same username but different bank' do
      user.logins.create(username: 'username', provider: 'test')
      post :create, params: { login: { bank: 'bank', username: 'username' } }
      expect(Login.count).to eq 2
    end

    it 'redirects if the request fails' do
      allow(request).to receive(:create).and_return 'error'
      post :create, params: { login: { username: 'username' } }
      expect(response).to redirect_to new_login_path
      expect(flash[:alert]).to eq 'error'
    end

    it 'saves the record if the request passes' do
      post :create, params: { login: { username: 'username' } }
      expect(Login.count).to eq 1
      expect(response).to render_template :create
    end

    it 'redirects if save fails' do
      post :create, params: { login: { username: nil } }
      expect(response).to redirect_to new_login_path
      expect(flash[:alert]).to eq login.errors.full_messages
    end
  end

  describe '#refresh' do
    before(:each) do
      user.logins.create(id: 123, username: 'before')
      allow(salt_login).to receive(:new).and_return request
      allow(request).to receive(:refresh).and_return(id: 123, username: 'after', accounts_attributes: [{ identifier: 123 }])
    end

    it 'redirects if the request fails' do
      allow(request).to receive(:refresh).and_return 'error'
      put :refresh, params: { id: 123 }
      expect(response).to redirect_to root_path
      expect(flash[:alert]).to eq 'error'
    end

    it 'updates login if request passes' do
      put :refresh, params: { id: 123 }
      expect(Account.count).to eq 1
      expect(login.username).to eq 'after'
      expect(response).to redirect_to root_path
      expect(flash[:alert]).to eq 'Login #123 was refreshed.'
    end
  end

  describe '#reconnect' do
    it 'renders reconnect template' do
      user.logins.create(id: 123, username: 'test')
      get :reconnect, params: { id: 123 }
      expect(response).to render_template :reconnect
    end
  end

  describe '#update' do
    before(:each) do
      user.logins.create(id: 123, username: 'before')
      allow(salt_login).to receive(:new).and_return request
      allow(request).to receive(:reconnect).and_return(id: 123, username: 'after')
    end

    it 'redirects if the request fails' do
      allow(request).to receive(:reconnect).and_return 'error'
      put :update, params: { id: 123, login: { username: 'before' } }
      expect(response).to redirect_to reconnect_login_path
      expect(flash[:alert]).to eq 'error'
    end

    it 'reconnects login if request passes' do
      put :update, params: { id: 123, login: { username: 'before' } }
      expect(login.username).to eq 'after'
      expect(response).to render_template :update
    end
  end

  describe '#destroy' do
    before(:each) do
      user.logins.create(id: 123, username: 'before')
      allow(salt_login).to receive(:new).and_return request
      allow(request).to receive(:destroy).and_return(id: 123)
    end

    it 'redirects if request fails' do
      allow(request).to receive(:destroy).and_return 'error'
      delete :destroy, params: { id: 123 }
      expect(response).to redirect_to root_path
      expect(flash[:alert]).to eq 'error'
    end

    it 'destroys login if request passes' do
      delete :destroy, params: { id: 123 }
      expect(Login.count).to eq 0
      expect(response).to redirect_to root_path
      expect(flash[:alert]).to eq 'Login with id: #123 was deleted'
    end
  end

  describe '#stage' do
    it 'gets @stage from json' do
      allow(salt_login).to receive(:stage).and_return 'test'
      get :stage, format: :json
      body = JSON.parse(response.body)
      expect(body['stage']).to eq 'test'
    end
  end
end