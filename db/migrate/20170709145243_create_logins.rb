class CreateLogins < ActiveRecord::Migration[5.1]
  def change
    create_table :logins, id: false do |t|
      t.primary_key :id
      t.string :username
      t.string :secret
      t.string :provider
      t.string :country
      t.string :status
      t.string :next_refresh
      t.string :error
      t.string :created_at
      t.string :updated_at
      t.references :user, foreign_key: true
      t.timestamps null: true
    end
  end
end
