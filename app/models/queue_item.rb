# frozen_string_literal: true

class QueueItem < ApplicationRecord

  enum status: {
    pending: 0,
    failed:  1,
    done:    2
  }

  belongs_to :bag

  validates :status, presence: true
  validates :bag_id, presence: true

  def user
    bag.user
  end

end
