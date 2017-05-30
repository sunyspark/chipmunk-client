Fabricator(:base_request, class_name: "Request") do
  type nil
  bag_id { SecureRandom.uuid }
  user { Fabricate(:user) }
  external_id { SecureRandom.uuid }
end

Fabricator(:audio_request, from: :base_request) do
  type "AudioRequest"
end

Fabricator(:digital_request, from: :base_request) do
  type "DigitalRequest"
end

Fabricator(:request) do
  initialize_with { Fabricate([:audio_request, :digital_request].sample) }
end
