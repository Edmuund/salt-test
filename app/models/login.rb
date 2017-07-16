class Login < ApplicationRecord
  belongs_to :user
  has_many :accounts, dependent: :destroy
  has_many :transactions, through: :accounts
  accepts_nested_attributes_for :accounts
  attr_accessor :pass, :bank

  validates_presence_of :username
end