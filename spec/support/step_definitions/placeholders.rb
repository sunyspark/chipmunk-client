# frozen_string_literal: true

# Placeholders have to be defined in the global scope

placeholder :upload_field do
  match(/upload\.([a-zA-Z0-9_]*)/) do |field|
    field
  end
end

placeholder :http_verb do
  match(/(GET|PATCH|POST|PUT|DELETE)/) do |verb|
    verb.downcase.to_sym
  end
end
