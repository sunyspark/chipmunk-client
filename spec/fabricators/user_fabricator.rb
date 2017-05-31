Fabricator(:user) do
  email { Faker::Internet.email }
  admin false
  api_key { SecureRandom.uuid }
end
