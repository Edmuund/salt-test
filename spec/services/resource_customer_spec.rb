require 'rails_helper'
require 'api_request'
CUSTOMER = ApiRequest::Resource::Customer

RSpec.describe CUSTOMER do
  before(:each) do
    @customer = CUSTOMER.new(nil)
  end
  let(:response) { @customer.create }

  describe 'initialize' do
    it 'creates an instance of Customer class' do
      expect(@customer.class).to be CUSTOMER
    end
  end

  describe 'create' do
    it 'returns an error if request fails' do
      stub_request(:post, 'https://www.saltedge.com/api/v3/customers/?data%5Bidentifier%5D=')
        .to_return(status: 400, body: { error_message: 'error' }.to_json)
      expect(response).to be_a String
    end

    it 'returns customer params hash if the request passes' do
      stub_request(:post, 'https://www.saltedge.com/api/v3/customers/?data%5Bidentifier%5D=')
        .to_return(body: { data: { id: 123, secret: 123 } }.to_json)
      expect(response).to be_a Hash
      expect(response).to eq(customer_id: 123, customer_secret: 123)
    end
  end
end