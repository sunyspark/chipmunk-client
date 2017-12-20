# frozen_string_literal: true

require "fileutils"

namespace :chipmunk do
  def create_paths(app_storage_path, app_upload_user_path, user_upload_path)
    # create rsync point
    FileUtils.mkdir_p(app_storage_path) unless File.exist?(app_storage_path)
    FileUtils.mkdir_p(app_upload_user_path) unless File.exist?(app_upload_user_path)
    FileUtils.symlink(app_upload_user_path, user_upload_path) unless File.exist?(user_upload_path)
  end

  def set_upload_config(upload_config_path, app_storage_path, app_upload_path, user_upload_path)
    # update upload.yml
    upload_config = YAML.load_file(upload_config_path)
    upload_config[Rails.env]["rsync_point"] = "localhost:#{user_upload_path}"
    upload_config[Rails.env]["storage_path"] = app_storage_path
    upload_config[Rails.env]["upload_path"] = app_upload_path
    YAML.dump(upload_config, File.new(upload_config_path, "w"))
    puts "Storage locations for #{Rails.env}:"
    puts YAML.dump(upload_config[Rails.env])
    puts
  end

  def set_client_config(username,client_config_path)
    # find/create user
    user = User.find_by_username(username)
    unless user
      user = User.create(username: username, email: "nobody@nowhere")
      user.save
    end
    puts "User API key for #{user.username}: #{user.api_key}"
    YAML.dump({ "api_key" => user.api_key}, File.new(client_config_path, "w"))
  end

  task setup: :environment do
    username = ENV["USER"]
    app_storage_path = "#{Rails.root}/repo/storage"
    app_upload_path = "#{Rails.root}/repo/incoming"
    user_upload_path = "#{Rails.root}/incoming"
    upload_config_path = "#{Rails.root}/config/upload.yml"
    client_config_path = "#{Rails.root}/config/client.yml"

    create_paths(app_storage_path, "#{app_upload_path}/#{username}", user_upload_path)
    set_upload_config(upload_config_path, app_storage_path, app_upload_path, user_upload_path)
    puts "Ensure #{username} can rsync via ssh with write access to:"
    puts "  localhost:#{user_upload_path}"
    puts

    set_client_config(username,client_config_path)
  end
end
