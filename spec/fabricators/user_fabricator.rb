# frozen_string_literal: true

Fabricator(:user) do
  email { Faker::Internet.email }
  username { Faker::Internet.user_name }
  admin false
  api_key { SecureRandom.uuid }
end
