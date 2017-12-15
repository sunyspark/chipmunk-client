# frozen_string_literal: true

class CollapseRequestIntoBag < ActiveRecord::Migration[5.1]
  def change
    add_index :bags, :bag_id, unique: true
    add_index :bags, :external_id, unique: true
    remove_column :queue_items, :request_id
    drop_table :requests
    change_column_null :bags, :storage_location, true
  end
end
