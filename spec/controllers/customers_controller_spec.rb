require 'rails_helper'

RSpec.describe CustomersController, type: :controller do
  let(:salt_customer) { CustomersController::SALT_CUSTOMER }
  let(:request)       { instance_double(salt_customer) }

  it 'redirects if request fails' do
    allow(salt_customer).to receive(:new).and_return(request)
    allow(request).to receive(:create).and_return 'error'
    @request.env['devise.mapping'] = Devise.mappings[:user]
    post :create, params: { user: { email: 'test@mail.com', password: 'password' } }
    expect(response).to redirect_to new_user_registration_path
    expect(flash[:alert]).to eq 'error'
  end

  it 'redirects if request fails' do
    allow(salt_customer).to receive(:new).and_return(request)
    allow(request).to receive(:create).and_return customer_id: 123
    @request.env["devise.mapping"] = Devise.mappings[:user]
    post :create, params: { user: { email: 'test@mail.com', password: 'password' } }
    expect(response).to redirect_to root_path
  end
end