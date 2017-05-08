Fabricator(:base_bag, class_name: "Bag") do
  type nil
  bag_id { SecureRandom.uuid }
  user { Fabricate(:user) }
  external_id { SecureRandom.uuid }
  storage_location { File.join Faker::Lorem.word, Faker::Lorem.word, Faker::Lorem.word }
end

Fabricator(:audio_bag, from: :base_bag, class_name: "AudioBag") do
  type "AudioBag"
end

Fabricator(:digital_bag, from: :base_bag, class_name: "DigitalBag") do
  type "DigitalBag"
end

Fabricator(:bag) do
  initialize_with { Fabricate([:audio_bag, :digital_bag].sample) }
end