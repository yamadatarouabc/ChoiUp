class MaterialsController < ApplicationController
  before_action :authenticate_user!

  def index
    @q = Material.ransack(params[:q])
    @materials = @q.result(distinct: true).order(created_at: :desc)
    # 検索キーワードの有無を判定
    @search_keyword = params.dig(:q, :title_cont)
    # @materials = Material.order(created_at: :desc).page(params[:page])
  end

  def new
    @material = Material.new
  end

  def create
    @material = Material.new(material_params)

    if @material.save
      # redirect_to material_path(@material), success: '教材を登録しました'
      redirect_to root_path, notice: "登録ありがとうございます。教材を登録しました"
    else
      flash.now[:danger] = "教材の登録に失敗しました"
      render :new, status: :unprocessable_entity
    end
  end

  def show
    @material = Material.find(params[:id])
    # N+1問題を防ぐため includes を使用
    @material.reviews.includes(:user)
    # @reviews = @material.reviews.order(created_at: :desc)
    # 後でkaminariを使ってページネーション予定
  end

  private

  def material_params
    params.require(:material).permit(:title, :url, :description)
  end
end
