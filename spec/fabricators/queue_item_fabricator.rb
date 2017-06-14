Fabricator(:queue_item) do
  request { Fabricate(:request) }
  bag { Fabricate(:bag) }
end