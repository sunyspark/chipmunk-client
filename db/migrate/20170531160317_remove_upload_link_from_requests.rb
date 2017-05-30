class RemoveUploadLinkFromRequests < ActiveRecord::Migration[5.1]
  def change
    remove_column :requests, :upload_link
  end
end
