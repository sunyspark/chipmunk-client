Fabricator(:queue_item) do
  request { Fabricate([:audio_request, :digital_request].sample) }
  bag { Fabricate(:bag) }
end