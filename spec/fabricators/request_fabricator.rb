Fabricator(:request, class_name: "Request") do
  bag_id { SecureRandom.uuid }
  user { Fabricate(:user) }
  external_id { SecureRandom.uuid }
  content_type { ["audio", "digital"].sample }
end

