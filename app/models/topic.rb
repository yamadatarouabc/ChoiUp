class Topic < ApplicationRecord
  has_many :review_topics, dependent: :destroy
  has_many :reviews, through: :review_topics

  validates :name, presence: true, uniqueness: true, length: { maximum: 50 }

  def self.find_or_create_from_input(input)
    normalized_name = input.to_s.strip.downcase
    return nil if normalized_name.empty?

    find_or_create_by!(name: normalized_name)
  end
end
