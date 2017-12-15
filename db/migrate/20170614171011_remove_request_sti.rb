# frozen_string_literal: true

class RemoveRequestSti < ActiveRecord::Migration[5.1]
  def change
    remove_column :requests, :type, :string, null: false, default: ""
    add_column :requests, :content_type, :string, null: false, default: "default"
  end
end
