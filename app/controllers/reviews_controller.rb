class ReviewsController < ApplicationController
  before_action :authenticate_user!

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
      @reviews = @material.reviews.includes(:user).order(created_at: :desc)
      render "materials/show", status: :unprocessable_entity
    end
  end


  private

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
