class Admin::TopicGroupsController < Admin::BaseController
  def index
    @topic_groups = TopicGroup.includes(:topics).to_a
    @topic_groups.sort_by! { |topic_group| [ topic_group.topics.size, topic_group.name ] }
    @review_counts = ReviewTopic.group(:topic_id).count
  end
end
