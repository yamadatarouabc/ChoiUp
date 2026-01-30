class ReviewsController < ApplicationController
  before_action :authenticate_user!

  def create
    set_material
    @review = @material.reviews.build(review_params)
    @review.user = current_user

    if @review.save
      redirect_to @material, notice: "評価を投稿しました"
    else
      redirect_to @material, alert: "評価の投稿に失敗しました: #{@review.errors.full_messages.join(', ')}"
    end
  end


  private

  def set_material
    @material = Material.find(params[:material_id])
  end

  def review_params
    params.require(:review).permit(:start_level, :difficulty_rating, :comment)
  end
end
