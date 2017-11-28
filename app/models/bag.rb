class Bag < ApplicationRecord

  belongs_to :user
  has_one :queue_item

  def to_param
    bag_id
  end

  validates :bag_id, presence: true, length: { minimum: 6 }
  validates :user_id, presence: true
  validates :external_id, presence: true

  # Declare the policy class to use for authz
  def self.policy_class
    BagPolicy
  end

  def src_path
    File.join(Rails.application.config.upload['upload_path'],user.username,bag_id)
  end
  
  def dest_path
    prefixes = bag_id.match(/^(..)(..)(..).*/)
    raise RuntimeError, "bag_id too short" unless prefixes
    File.join(Rails.application.config.upload['storage_path'],*prefixes[1..3],bag_id)
  end

  def upload_link
    File.join(Rails.application.config.upload['rsync_point'],bag_id)
  end

  def external_validation_cmd
    [Rails.application.config.validation[content_type.to_s],external_id,src_path].join(" ")
  end

end
