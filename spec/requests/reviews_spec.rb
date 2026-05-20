require "rails_helper"

RSpec.describe "Reviews", type: :request do
  let(:material) { create(:material) }
  let(:user) { create(:user) }
  let(:valid_params) do
    {
      review: {
        start_level: "complete_beginner",
        difficulty_rating: "just_right",
        comment: "良かった"
      }
    }
  end
  let(:invalid_params) do
    {
      review: {
        start_level: "",
        difficulty_rating: "",
        comment: ""
      }
    }
  end

  describe "POST /materials/:material_id/reviews" do
    context "未ログイン" do
      it "Review が作成されない（認可・異常系）" do
        expect {
          post material_reviews_path(material), params: valid_params
        }.not_to change(Review, :count)
      end

      it "ログイン画面にリダイレクトする" do
        post material_reviews_path(material), params: valid_params
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "ログイン済み + 正常パラメータ" do
      before { sign_in user }

      it "Review が 1 件増える" do
        expect {
          post material_reviews_path(material), params: valid_params
        }.to change(Review, :count).by(1)
      end

      it "material_path にリダイレクトし、notice flash が立つ" do
        post material_reviews_path(material), params: valid_params
        expect(response).to redirect_to(material_path(material))
        expect(flash[:notice]).to include("評価を投稿しました")
      end

      it "作成された Review の user は current_user、material は URL の material と一致する" do
        post material_reviews_path(material), params: valid_params
        review = Review.last
        expect(review.user).to eq(user)
        expect(review.material).to eq(material)
      end
    end

    context "ログイン済み + 不正パラメータ" do
      before { sign_in user }

      it "Review が増えない（異常系）" do
        expect {
          post material_reviews_path(material), params: invalid_params
        }.not_to change(Review, :count)
      end

      it "422 を返し、エラー表示用 flash がレンダリングされる" do
        post material_reviews_path(material), params: invalid_params
        # Rack 3.x で :unprocessable_entity は deprecated、:unprocessable_content に改名
        expect(response).to have_http_status(:unprocessable_content)
        expect(response.body).to include("評価の投稿に失敗しました")
      end
    end

    context "ログイン済み + 一意性違反（同一 user と 同一 material で 2 回 POST）" do
      before { sign_in user }

      it "2 回目では Review が増えない（異常系）" do
        post material_reviews_path(material), params: valid_params
        expect {
          post material_reviews_path(material), params: valid_params
        }.not_to change(Review, :count)
      end

      it "2 回目は 422 を返し、一意性違反のメッセージが body に含まれる" do
        post material_reviews_path(material), params: valid_params
        post material_reviews_path(material), params: valid_params
        expect(response).to have_http_status(:unprocessable_content)
        expect(response.body).to include("同じ教材に対して1回のみ評価できます")
      end
    end

    context "存在しない material_id" do
      before { sign_in user }

      it "404 を返す（異常系）" do
        nonexistent_id = Material.maximum(:id).to_i + 1
        post material_reviews_path(material_id: nonexistent_id), params: valid_params
        expect(response).to have_http_status(:not_found)
      end
    end

    context "Strong Parameters" do
      before { sign_in user }

      it "review[user_id] に他ユーザー ID を混入させても、保存される user は current_user のまま" do
        other_user = create(:user)
        post material_reviews_path(material), params: {
          review: valid_params[:review].merge(user_id: other_user.id)
        }
        expect(Review.last.user).to eq(user)
      end
    end

    context "ログイン済み + topic_names を含む" do
      before { sign_in user }

      it "カンマ区切り 2 件で Topic 2 件が紐づく（正常系）" do
        post material_reviews_path(material), params: {
          review: valid_params[:review].merge(topic_names: "ruby, rails")
        }
        expect(Review.last.topics.pluck(:name)).to contain_exactly("ruby", "rails")
      end
      it "topic_names が空文字でも Review は作成され、topic は 0 件（境界・正常系）" do
        expect {
          post material_reviews_path(material), params: {
            review: valid_params[:review].merge(topic_names: "")
          }
        }.to change(Review, :count).by(1)
        expect(Review.last.topics).to be_empty
      end
      it "topic_names 未指定でも Review は作成される（境界・正常系）" do
        expect {
          post material_reviews_path(material), params: valid_params
        }.to change(Review, :count).by(1)
        expect(Review.last.topics).to be_empty
      end
      it "同じレビュー内 'ruby, ruby' は Topic 1 件のみ紐づく（uniq による重複除去）" do
        post material_reviews_path(material), params: {
          review: valid_params[:review].merge(topic_names: "ruby, ruby")
        }
        expect(Review.last.topics.pluck(:name)).to eq([ "ruby" ])
      end
      it "同じレビュー内 'Ruby, ruby' は Topic 1 件のみ紐づく（正規化 + uniq）" do
        post material_reviews_path(material), params: {
          review: valid_params[:review].merge(topic_names: "Ruby, ruby")
        }
        expect(Review.last.topics.pluck(:name)).to eq([ "ruby" ])
      end
      it "同じレビュー内 'ruby, , rails' は空白要素を無視して 2 件紐づく（filter_map）" do
        post material_reviews_path(material), params: {
          review: valid_params[:review].merge(topic_names: "ruby, , rails")
        }
        expect(Review.last.topics.pluck(:name)).to contain_exactly("ruby", "rails")
      end
      it "異なるレビューで 'Ruby' と 'ruby' を送ると同じ Topic に寄る（Topic マスタの正規化）" do
        post material_reviews_path(material), params: {
          review: valid_params[:review].merge(topic_names: "Ruby")
        }
        other_material = create(:material)
        post material_reviews_path(other_material), params: {
          review: valid_params[:review].merge(topic_names: "ruby")
        }
        expect(Topic.where(name: "ruby").count).to eq(1)
      end
    end
  end
end
