class CreateTransactions < ActiveRecord::Migration[5.1]
  def change
    create_table :transactions do |t|
      t.string :identifier
      t.string :category
      t.string :currency
      t.string :amount
      t.string :description
      t.string :account_balance_snapshot
      t.string :categorization_confidence
      t.string :made_on
      t.string :mode
      t.boolean :duplicated
      t.string :status
      t.string :created_at
      t.string :updated_at
      t.references :account, foreign_key: true
      t.timestamps null: true
    end
  end
end