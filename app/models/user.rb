# frozen_string_literal: true

class User < ApplicationRecord

  validates :email, presence: true
  validates :admin, inclusion: { in: [true, false] }
  validates :api_key, presence: true
  validates :username, presence: true

  # Assign an API key
  before_create do |user|
    user.api_key = user.generate_api_key
  end

  # Generate a unique API key
  def generate_api_key
    SecureRandom.uuid.delete("-")
  end

end
