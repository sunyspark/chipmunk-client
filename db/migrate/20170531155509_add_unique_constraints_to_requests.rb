class AddUniqueConstraintsToRequests < ActiveRecord::Migration[5.1]
  def change
    add_index :requests, :external_id, unique: true
  end
end
