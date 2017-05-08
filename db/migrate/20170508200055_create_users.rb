class CreateUsers < ActiveRecord::Migration[5.1]
  def change
    create_table :users do |t|
      t.string :email, null: false, default: ""
      t.boolean :admin, null: false, default: false
      t.string :api_key, null: false, default: "x"
      t.timestamps
    end

    add_index :users, :email, unique: true

  end
end
