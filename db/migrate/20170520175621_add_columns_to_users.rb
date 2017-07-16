class AddColumnsToUsers < ActiveRecord::Migration[5.1]
  def change
    add_column :users, :customer_id, :integer
    add_column :users, :customer_secret, :string
  end
end
