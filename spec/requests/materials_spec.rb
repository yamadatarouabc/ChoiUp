require "rails_helper"

RSpec.describe "Materials", type: :request do
  describe "GET /materials" do
    it "未ログインでも 200 を返す（正常系）" do
      get materials_path
      expect(response).to have_http_status(:ok)
    end

    it "登録済みの教材が body に含まれる（正常系）" do
      create(:material, title: "Ruby 入門")
      create(:material, title: "Python 入門")
      get materials_path
      expect(response.body).to include("Ruby 入門")
      expect(response.body).to include("Python 入門")
    end

    it "?q[title_cont] で絞り込みが効く（正常系）" do
      create(:material, title: "Ruby 入門")
      create(:material, title: "Python 入門")
      get materials_path, params: { q: { title_cont: "Ruby" } }
      expect(response.body).to include("Ruby 入門")
      expect(response.body).not_to include("Python 入門")
    end
  end

  describe "GET /materials/:id" do
    let(:material) { create(:material, title: "Rails ガイド", description: "詳しい解説", url: "https://example.com/rails") }

    it "未ログインでも 200 を返す（正常系）" do
      get material_path(material)
      expect(response).to have_http_status(:ok)
    end

    it "title / description / URL が body に含まれる（正常系）" do
      get material_path(material)
      expect(response.body).to include("Rails ガイド")
      expect(response.body).to include("詳しい解説")
      expect(response.body).to include("https://example.com/rails")
    end

    it "存在しない id だと 404 を返す（異常系）" do
      # Rails 7.1+ は test 環境でも RecordNotFound を rescue して 404 レスポンスに変換する
      nonexistent_id = Material.maximum(:id).to_i + 1
      get material_path(id: nonexistent_id)
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "GET /materials/new" do
    context "未ログイン" do
      it "ログイン画面にリダイレクトする（認可・異常系）" do
        get new_material_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "ログイン済み" do
      it "200 を返す（正常系）" do
        sign_in create(:user)
        get new_material_path
        expect(response).to have_http_status(:ok)
      end
    end
  end

  describe "POST /materials" do
    let(:valid_params) do
      { material: { title: "新教材", url: "https://example.com/new", description: "説明" } }
    end
    let(:invalid_params) do
      { material: { title: "", url: "https://example.com/new", description: "説明" } }
    end

    context "未ログイン" do
      it "Material が作成されない（認可・異常系）" do
        expect {
          post materials_path, params: valid_params
        }.not_to change(Material, :count)
      end

      it "ログイン画面にリダイレクトする" do
        post materials_path, params: valid_params
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "ログイン済み + 正常パラメータ" do
      before { sign_in create(:user) }

      it "Material が 1 件増える" do
        expect {
          post materials_path, params: valid_params
        }.to change(Material, :count).by(1)
      end

      it "root_path にリダイレクトし、notice flash が立つ" do
        post materials_path, params: valid_params
        expect(response).to redirect_to(root_path)
        expect(flash[:notice]).to include("教材を登録しました")
      end
    end

    context "ログイン済み + 不正パラメータ" do
      before { sign_in create(:user) }

      it "Material が増えない（異常系）" do
        expect {
          post materials_path, params: invalid_params
        }.not_to change(Material, :count)
      end

      it "422 を返し、エラー表示用 flash がレンダリングされる" do
        post materials_path, params: invalid_params
        # Rack 3.x で :unprocessable_entity は deprecated、:unprocessable_content に改名
        expect(response).to have_http_status(:unprocessable_content)
        expect(response.body).to include("教材の登録に失敗しました")
      end
    end

    context "Strong Parameters" do
      before { sign_in create(:user) }

      it "許可外の属性（id 指定など）は無視される" do
        # 許可外属性として id を指定しても、AR が新規作成時にこれを採用しない（permit 漏れ）ことを確認
        injected_id = Material.maximum(:id).to_i + 1
        post materials_path, params: {
          material: valid_params[:material].merge(id: injected_id)
        }
        expect(Material.find_by(id: injected_id)).to be_nil
      end
    end
  end
end
