# frozen_string_literal: true

Resque.redis.namespace = "chipmunk:#{ENV["RAILS_ENV"]}"
