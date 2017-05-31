class QueueItem < ApplicationRecord

  belongs_to :request
  belongs_to :bag, optional: true # belongs_to adds a presence validator by default
                                  # we disable it here

  validates :request_id, presence: true

  def user
    request.user
  end

end