Fabricator(:queue_item) do
  request { Fabricate([:audio_request, :digital_request].sample) }
  bag { Fabricate([:audio_bag, :digital_bag].sample) }
end