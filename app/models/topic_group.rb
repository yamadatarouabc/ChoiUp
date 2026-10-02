class TopicGroup < ApplicationRecord
  has_many :topics

  validates :name, presence: true, uniqueness: true, length: { maximum: 50 }

  def self.find_or_create_from_input(input)
    normalized_name = input.to_s.strip.downcase
    return nil if normalized_name.empty?

    find_or_create_by!(name: normalized_name)
  end

  def self.assign_topics!(group_name, topic_names)
    topic_group = find_or_create_from_input(group_name)
    return nil if topic_group.nil?

    topic_names.each do |topic_name|
      topic = Topic.find_or_create_from_input(topic_name)
      next if topic.nil?

      topic.update!(topic_group: topic_group)
    end

    topic_group
  end
end
