require 'rails_helper'
require 'api_request'
REQUEST = ApiRequest::SingleRequest

RSpec.describe REQUEST do
  let(:run)      { @request.run }
  let(:response) { REQUEST.response }
  let(:error)    { REQUEST.error }

  before(:each) do
    @request = REQUEST.new('https://test.com', :get, {}, {})
  end

  describe 'initialize' do
    it 'creates an instance of SingleRequest class' do
      expect(@request.class).to be REQUEST
    end
  end

  describe 'run' do
    it 'populates response if the request passes' do
      stub_request(:any, 'https://test.com')
        .to_return(status: 200, body: { data: { response: 'successful' } }.to_json)
      run
      expect(response).not_to be nil
      expect(error).to be nil
    end

    it 'populates error if the request fails' do
      stub_request(:any, 'https://test.com')
        .to_return(status: 400, body: { error_message: 'error' }.to_json)
      run
      expect(response).to be nil
      expect(error).not_to be nil
    end

    it 'populates error if the request timed out' do
      stub_request(:any, 'https://test.com').to_timeout
      run
      expect(response).to be nil
      expect(error).to eq 'Something went wrong. Timeout was reached.'
    end

    it 'filters out secret data from the error' do
      stub_request(:any, 'https://test.com')
        .to_return(status: 404, body: { error_message: 'Client with secret: 12345 does not exist' }.to_json)
      run
      expect(response).to be nil
      expect(error).to eq 'Error 404: Client with secret: <filtered> does not exist'
    end

    it 'deletes the id of the existing resource' do
      stub_request(:any, 'https://test.com')
        .to_return(status: 400, body: { error_message: 'Customer already exists with id 12345' }.to_json)
      run
      expect(response).to be nil
      expect(error).to eq 'Error 400: Customer already exists'
    end
  end
end