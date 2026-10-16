require "rails_helper"

RSpec.describe "Admin::TopicGroups", type: :request do
  describe "GET /admin/topic_groups" do
    it "権限者はアクセスできる（正常系）" do
      sign_in create(:user, role: :admin)
      get admin_topic_groups_path
      expect(response).to have_http_status(:ok)
    end

    it "一般の利用者は 404（異常系）" do
      sign_in create(:user)
      get admin_topic_groups_path
      expect(response).to have_http_status(:not_found)
    end

    it "未ログインは 404 で、ログイン画面へ飛ばさない（異常系）" do
      # authenticate_user! を使うとログイン画面へリダイレクト（302）になり、
      # このパスに何かがあることを教えてしまう。404 に揃えて存在を隠す。
      get admin_topic_groups_path
      expect(response).to have_http_status(:not_found)
    end
  end
end
