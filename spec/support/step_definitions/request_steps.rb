# frozen_string_literal: true

require "rack/test"

module RequestSteps

  step "I send and accept JSON" do
    header "Accept", "application/json"
    header "Content-Type", "application/json"
  end

  step "I send a :http_verb request for/to :url" do |verb, url|
    request url, method: verb
  end

  step "I send a :http_verb request for/to :url with this json:" do |verb, url, table|
    request(url,
      method: verb,
      params: table.rows_hash.to_json)
  end

  step "I send an empty POST request to :url" do |url|
    request(url, method: :post, params: {}.to_json)
  end

  step "the response should have the following headers:" do |table|
    table.rows_hash.each do |header, value|
      expect(last_response.get_header(header)).to eql(value)
    end
  end

  step "the response should be empty" do
    expect(last_response.body).to eql("")
  end

  step "the response status should be :status" do |status|
    expect(last_response.status).to eql(Integer(status))
  end

  step "the json/JSON response should be:" do |table|
    expect(JSON.parse(last_response.body)).to eql(adjust_table_hash(table.rows_hash))
  end

  private

  def adjust_table_hash(hash)
    hash["id"] ? hash["id"] = Integer(hash["id"]) : nil
    hash["stored"] ? hash["stored"] = ActiveModel::Type::Boolean.new.cast(hash["stored"]) : nil
    hash
  end
end

RSpec.configure {|config| config.include RequestSteps }
