require 'rails_helper'
require 'api_request'
LOGIN = ApiRequest::Resource::Login

RSpec.describe LOGIN do
  before(:each) do
    @user = User.create(email: 'test@mail.com', password: 'password', customer_secret: 'secret')
    @login = LOGIN.new(@user)

    stub_request(:post, /login/).to_return(status: 200, body: { data: { secret: 'secret' } }.to_json)
    stub_request(:put, /login/).to_return(status: 200, body: { data: { secret: 'secret' } }.to_json)
    stub_request(:get, /login/)
      .to_return(status: 200, body: { data: { id: 123, secret: 'secret', status: 'active',
                                              next_refresh_possible_at: '11-11-11',
                                              last_attempt: {}, created_at: '11-11-11',
                                              updated_at: '11-11-11' } }.to_json)
    stub_request(:get, /accounts/)
      .to_return(status: 200, body: { data: [{ id: 123,
                                               created_at: '11-11-11',
                                               updated_at: '11-11-11',
                                               extra: { transactions_count: {} } }] }.to_json)
    stub_request(:get, 'https://www.saltedge.com/api/v3/transactions')
      .to_return(status: 200, body: { data: [{ id: 123,
                                               account_id: 123,
                                               status: 'posted',
                                               created_at: '11-11-11',
                                               updated_at: '11-11-11', extra: {} }] }.to_json)
    stub_request(:get, 'https://www.saltedge.com/api/v3/transactions/pending')
      .to_return(status: 200, body: { data: [{ id: 123,
                                               account_id: 123,
                                               status: 'pending',
                                               created_at: '11-11-11',
                                               updated_at: '11-11-11', extra: {} }] }.to_json)
    stub_request(:delete, /login/)
      .to_return(status: 200, body: { data: { id: 123 } }.to_json)
  end

  describe 'initialize' do
    it 'creates an instance of Login class' do
      expect(@login.class).to be LOGIN
    end
  end

  describe 'create' do
    let(:response) { @login.create }

    it 'returns an error if the any of the requests fail' do
      stub_request(:post, /login/)
        .to_return(status: 400, body: { error_message: 'error' }.to_json)
      expect(response).to be_a String
    end

    it 'exits the method if login status is inactive' do
      stub_request(:get, /login/)
        .to_return(status: 200, body: { data: { id: 123, secret: 'secret', status: 'inactive',
                                                next_refresh_possible_at: '11-11-11',
                                                last_attempt: {}, created_at: '11-11-11',
                                                updated_at: '11-11-11' } }.to_json)
      expect(response[:accounts_attributes]).to eq []
    end

    it 'fetches accounts and transactions if login status is active' do
      expect(response[:accounts_attributes]).not_to be []
      expect(response[:accounts_attributes].first[:transactions_attributes]).not_to be []
    end
  end

  describe 'reconnect and refresh' do
    let(:response) { @login.reconnect }
    let(:refresh)  { @login.refresh }

    before(:each) do
      existing_login = @user.logins.new(username: 'username')
      account = existing_login.accounts.new(identifier: 123)
      account.transactions.new(identifier: 123, status: 'pending')
      existing_login.save
      @login = LOGIN.new(@user, existing_login: existing_login)
    end

    it 'returns an error if any of the requests fail' do
      stub_request(:put, /login/)
        .to_return(status: 400, body: { error_message: 'error' }.to_json)
      expect(response && refresh).to be_a String
    end

    it 'exits the method if login status is inactive' do
      stub_request(:get, /login/)
        .to_return(status: 200, body: { data: { id: 123, secret: 'secret', status: 'inactive',
                                                next_refresh_possible_at: '11-11-11',
                                                last_attempt: {}, created_at: '11-11-11',
                                                updated_at: '11-11-11' } }.to_json)
      expect(response[:accounts_attributes] & refresh[:accounts_attributes]).to eq []
    end

    it 'fetches accounts, transactions and deletes pending transactions if login status is active' do
      expect(response[:accounts_attributes]).not_to be []
      expect(Transaction.where(status: 'pending').count).to eq 0
      expect(refresh[:accounts_attributes]).not_to be []
      expect(Transaction.where(status: 'pending').count).to eq 0
      expect(response[:accounts_attributes].first[:transactions_attributes] &
              refresh[:accounts_attributes].first[:transactions_attributes]).not_to be []
    end
  end

  describe 'destroy' do
    let(:response) { @login.destroy }

    before(:each) do
      existing_login = @user.logins.new(username: 'username')
      account = existing_login.accounts.new(identifier: 123)
      account.transactions.new(identifier: 123, status: 'pending')
      existing_login.save
      @login = LOGIN.new(@user, existing_login: existing_login)
    end

    it 'returns an error if any of the requests fail' do
      stub_request(:delete, /login/)
        .to_return(status: 400, body: { error_message: 'error' }.to_json)
      expect(response).to be_a String
    end

    it 'returns the id of the deleted login' do
      expect(response).to eq 123
    end
  end
end