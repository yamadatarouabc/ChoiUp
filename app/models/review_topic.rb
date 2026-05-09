class ReviewTopic < ApplicationRecord
  belongs_to :review
  belongs_to :topic

  validates :review_id, uniqueness: { scope: :topic_id }
end
