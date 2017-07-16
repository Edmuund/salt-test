class Account < ApplicationRecord
  belongs_to :login
  has_many :transactions, dependent: :destroy
  accepts_nested_attributes_for :transactions
end
