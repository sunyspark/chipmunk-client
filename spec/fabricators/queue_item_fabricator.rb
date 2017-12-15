# frozen_string_literal: true

Fabricator(:queue_item) do
  bag { Fabricate(:bag) }
end
