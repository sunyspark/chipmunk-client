# frozen_string_literal: true

require "resque/tasks"
require "resque/pool/tasks"

task "resque:setup" => :environment do
  require "resque"
  Resque.redis.namespace = "chipmunk:#{Rails.env}"
end

task "resque:pool:setup" do
  ActiveRecord::Base.connection.disconnect!
  Resque::Pool.after_prefork do |_job|
    ActiveRecord::Base.establish_connection
    Resque.redis.client.reconnect
  end
end
