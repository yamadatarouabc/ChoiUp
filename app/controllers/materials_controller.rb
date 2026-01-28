class MaterialsController < ApplicationController
  before_action :authenticate_user!

  def index
    @materials = Material.order(created_at: :desc)
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
  end

  private

  def material_params
    params.require(:material).permit(:title, :url, :description)
  end
end
