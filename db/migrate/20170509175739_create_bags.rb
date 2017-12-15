# frozen_string_literal: true

class CreateBags < ActiveRecord::Migration[5.1]
  def change
    create_table :bags do |t|
      t.string :bag_id, null: false
      t.string :type, null: false
      t.integer :user_id, null: false
      t.string :external_id, null: false
      t.string :storage_location, null: false
      t.timestamps
    end

    add_index :bags, :user_id, unique: false
    add_foreign_key :bags, :users
  end
end
