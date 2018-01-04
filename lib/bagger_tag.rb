#!ruby
# frozen_string_literal: true

require "set"

class BaggerTag
  def self.from_hash(hash)
    raise ArgumentError, "exactly one key expected" unless hash.size == 1

    name = hash.keys.first
    params = hash.values.first

    raise ArgumentError, "fieldRequired is required" if params["fieldRequired"].nil?

    new(
      name: name,
      required: params["fieldRequired"],
      allowed_values: (Set.new(params["valueList"]) if params["valueList"])
)
  end

  attr_reader :name

  def initialize(name:, required:, allowed_values: nil)
    @name = name
    @required = required
    @allowed_values = allowed_values
  end

  def value_valid?(value)
    present_if_required?(value) && allowed_value?(value)
  end

  private

  attr_reader :allowed_values, :required

  def present_if_required?(value)
    result = !(required && value.nil?)
    puts "#{name} is required but not present" unless result
    result
  end

  def allowed_value?(value)
    result = value.nil? || !allowed_values || allowed_values.include?(value)
    puts "#{name}: \"#{value}\" is not an allowed value" unless result
    result
  end
end
