class Request < ApplicationRecord

  belongs_to :user
  has_one :queue_item

  def to_param
    bag_id
  end

  validates :bag_id, presence: true
  validates :user_id, presence: true
  validates :external_id, presence: true

  def self.policy_class
    RequestPolicy
  end

  def upload_path
    File.join(Rails.application.config.upload['upload_path'],user.username,bag_id)
  end

  def upload_link
    File.join(Rails.application.config.upload['rsync_point'],bag_id)
  end

end
