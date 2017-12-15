# frozen_string_literal: true

# Copyright (c) 2015 The Regents of the University of Michigan.
# All Rights Reserved.
# Licensed according to the terms of the Revised BSD License
# See LICENSE.md for details.

source "https://rubygems.org"

gem "bcrypt", "~> 3.1.7"
gem "jbuilder"
gem "pundit"
gem "rack-cors"
gem "rails", "~> 5.1.0"
gem "resque"
gem "resque-pool"
# cli - should separate out
gem "bagit"
gem "rest-client"

group :development, :test do
  gem "byebug", platforms: [:mri]
  gem "fabrication"
  gem "faker"
  gem "pry"
  gem "pry-byebug"
  gem "rails-controller-testing"
  gem "sqlite3"
end

group :test do
  gem "rspec"
  gem "rspec-activejob"
  gem "rspec-rails"
  gem "simplecov"
  gem "timecop"
  gem "turnip"
  gem "webmock"
end

group :development do
  gem "rubocop"
end
