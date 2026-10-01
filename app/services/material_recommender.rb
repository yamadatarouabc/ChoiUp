class MaterialRecommender
  MAX_LIMIT = 50
  TOP_TOPIC_LIMIT = 5

  def initialize(user)
    @user = user
  end

  def recommend(limit: 10)
    safe_limit = limit.to_i.clamp(1, MAX_LIMIT)
    usage_counts = @user.reviews.joins(:topics).group("topics.topic_group_id").count
    top_usage_pairs = usage_counts.sort_by { |_topic_group_id, count| -count }.first(TOP_TOPIC_LIMIT)
    top_user_topic_group_ids = top_usage_pairs.map { |topic_group_id, _count| topic_group_id }
    return Material.none if top_user_topic_group_ids.empty?

    user_reviewed_material_ids = @user.reviews.select(:material_id)

    Material
      .where.not(id: user_reviewed_material_ids)
      .joins(reviews: :topics)
      .where(topics: { topic_group_id: top_user_topic_group_ids })
      .select("materials.*, COUNT(DISTINCT (reviews.id, topics.topic_group_id)) AS matched_review_topic_groups_count")
      .group("materials.id")
      .order(matched_review_topic_groups_count: :desc)
      .limit(safe_limit)
  end
end
