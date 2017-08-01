require 'rails_helper'

RSpec.describe Login, type: :model do
  let(:user)  { User.create(email: 'test@mail.com') }
  let(:login) { user.logins.new(username: 'test', accounts_attributes: [{ transactions_attributes: [{}] }]) }

  it 'is not valid without username' do
    login = user.logins.new(username: nil)
    expect(login.save).to be_falsey
  end

  it 'accepts nested attributes' do
    expect(login.save).to be_truthy
    expect(Account.count).not_to be 0
    expect(Transaction.count).not_to be 0
  end

  it 'destroys nested resources through logins' do
    login.save
    expect(login.destroy).to be_truthy
    expect(Account.count).to be 0
    expect(Transaction.count).to be 0
  end
end
