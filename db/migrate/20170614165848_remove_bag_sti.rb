# frozen_string_literal: true

class RemoveBagSti < ActiveRecord::Migration[5.1]
  def change
    remove_column :bags, :type, :string, null: false, default: ""
    add_column :bags, :content_type, :string, null: false, default: "default"
  end
end
