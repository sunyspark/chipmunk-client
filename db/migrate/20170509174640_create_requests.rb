# frozen_string_literal: true

class CreateRequests < ActiveRecord::Migration[5.1]
  def change
    create_table :requests do |t|
      t.string :bag_id, null: false
      t.string :type, null: false
      t.integer :user_id, null: false
      t.string :external_id, null: false
      t.timestamps
    end

    add_index :requests, :bag_id, unique: true
    add_index :requests, :external_id, unique: true
    add_index :requests, :user_id, unique: false
    add_foreign_key :requests, :users
  end
end
