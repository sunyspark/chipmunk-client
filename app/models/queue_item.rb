class QueueItem < ApplicationRecord

  enum status: {
    pending: 0,
    failed: 1,
    done: 2
  }

  belongs_to :request
  belongs_to :bag, optional: true # belongs_to adds a presence validator by default
                                  # we disable it here

  validates :status, presence: true
  validates :request_id, presence: true

  def user
    request.user
  end

end