class Bag < ApplicationRecord

  belongs_to :user

  def to_param
    :bag_id
  end

  validates :bag_id, presence: true
  validates :user_id, presence: true
  validates :storage_location, presence: true
  validates :external_id, presence: true

  # Declare the policy class to use for authz
  def self.policy_class
    BagPolicy
  end

end
