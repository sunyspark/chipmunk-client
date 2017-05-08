class Request < ApplicationRecord

  belongs_to :user
  has_one :queue_item

  def to_param
    :bag_id
  end

  validates :bag_id, presence: true
  validates :user_id, presence: true
  validates :upload_link, presence: true
  validates :external_id, presence: true

  def self.policy_class
    RequestPolicy
  end

end
