class Topic < ApplicationRecord
  belongs_to :topic_group

  has_many :review_topics, dependent: :destroy
  has_many :reviews, through: :review_topics

  validates :name, presence: true, uniqueness: true, length: { maximum: 50 }

  # 分野の作成は必ずこのメソッドを通す。
  # Topic.create を直接呼ぶと topic_group_id が空になり NOT NULL 制約違反で失敗する。
  def self.find_or_create_from_input(input)
    normalized_name = input.to_s.strip.downcase
    return nil if normalized_name.empty?

    topic_group = TopicGroup.find_or_create_from_input(input)
    find_or_create_by!(name: normalized_name) { |topic| topic.topic_group = topic_group }
  end
end
