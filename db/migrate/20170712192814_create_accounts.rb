class CreateAccounts < ActiveRecord::Migration[5.1]
  def change
    create_table :accounts do |t|
      t.string :identifier
      t.string :currency
      t.string :name
      t.string :nature
      t.string :balance
      t.string :iban
      t.string :cards
      t.string :swift
      t.string :client_name
      t.string :account_name
      t.string :account_number
      t.string :available_amount
      t.string :credit_limit
      t.string :posted
      t.string :pending
      t.string :created_at
      t.string :updated_at
      t.references :login, foreign_key: true
      t.timestamps null: true
    end
  end
end