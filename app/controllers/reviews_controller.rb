class ReviewsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_own_review, only: [ :edit, :update, :destroy ]

  def create
    set_material
    @review = @material.reviews.build(review_params)
    @review.user = current_user

    if @review.save
      assign_topics(@review, @review.topic_names)
      redirect_to material_path(@material), notice: "評価を投稿しました"
    else
      # redirect_to @material, alert: "評価の投稿に失敗しました: #{@review.errors.full_messages.join(', ')}"
      flash.now[:alert] = "評価の投稿に失敗しました: #{@review.errors.full_messages.join(', ')}"
      @reviews = @material.reviews.includes(:user, :topics).order(created_at: :desc)
      render "materials/show", status: :unprocessable_entity
    end
  end

  def edit
    @review.topic_names = @review.topics.map(&:name).join(", ")
  end

  def update
    if @review.update(review_params)
      assign_topics(@review, @review.topic_names)
      redirect_to material_path(@material), notice: "評価を更新しました"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @review.destroy!
    redirect_to material_path(@material), notice: "評価を削除しました"
  end

  private

  # current_user 配下から探すので、他人のレビューは RecordNotFound（404）になり認可を兼ねる
  def set_own_review
    @review = current_user.reviews.find(params[:id])
    @material = @review.material
  end

  def set_material
    @material = Material.find(params[:material_id])
  end

  def review_params
    params.require(:review).permit(:start_level, :difficulty_rating, :comment, :topic_names)
  end

  def assign_topics(review, topic_names)
    review.topics = topic_names.to_s.split(",").filter_map do |name|
      Topic.find_or_create_from_input(name)
    end.uniq
  end
end
