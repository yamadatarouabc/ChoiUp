class MaterialRecommender
  MAX_LIMIT = 50
  TOP_TOPIC_LIMIT = 5

  def initialize(user)
    @user = user
  end

  def recommend(limit: 10)
    safe_limit = limit.to_i.clamp(1, MAX_LIMIT)
    usage_counts = @user.reviews.joins(:topics).group("topics.id").count
    top_usage_pairs = usage_counts.sort_by { |_topic_id, count| -count }.first(TOP_TOPIC_LIMIT)
    top_user_topic_ids = top_usage_pairs.map { |topic_id, _count| topic_id }
    return Material.none if top_user_topic_ids.empty?

    user_reviewed_material_ids = @user.reviews.select(:material_id)

    Material
      .where.not(id: user_reviewed_material_ids)
      .joins(reviews: :topics)
      .where(topics: { id: top_user_topic_ids })
      .select("materials.*, COUNT(DISTINCT review_topics.id) AS matched_review_topics_count")
      .group("materials.id")
      .order(matched_review_topics_count: :desc)
      .limit(safe_limit)
  end
end
