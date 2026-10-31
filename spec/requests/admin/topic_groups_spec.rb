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

    context "権限者としてアクセスしたとき" do
      before { sign_in create(:user, role: :admin) }

      it "グループが 0 件でも、空であることが分かる（正常系）" do
        get admin_topic_groups_path
        expect(response).to have_http_status(:ok)
        expect(response.body).to include("グループがありません")
      end

      it "属する分野が 1 つだけのグループは未整理として表示される（正常系）" do
        lone_group = create(:topic_group, name: "lone_group")
        create(:topic, name: "lone_topic", topic_group: lone_group)
        get admin_topic_groups_path
        expect(response.body).to include("未整理")
      end

      it "属する分野が複数なら、すべて表示される（正常系）" do
        shared_group = create(:topic_group, name: "shared_group")
        create(:topic, name: "first_topic", topic_group: shared_group)
        create(:topic, name: "second_topic", topic_group: shared_group)
        get admin_topic_groups_path
        expect(response.body).to include("first_topic")
        expect(response.body).to include("second_topic")
      end

      it "一度も使われていない分野も 0 件として表示される（正常系）" do
        unused_group = create(:topic_group, name: "unused_group")
        create(:topic, name: "unused_topic", topic_group: unused_group)
        get admin_topic_groups_path
        expect(response.body).to include("unused_topic")
        expect(response.body).to include("使用 0 件")
      end

      it "同じレビューに同じグループの分野が 2 つあっても、分野ごとに 1 件ずつ数える（正常系）" do
        # 教材のおすすめは同じレビュー内で同じグループを二重に数えないが、
        # この画面は「その分野がどれだけ使われているか」を分野ごとに数える。
        shared_group = create(:topic_group, name: "shared_group")
        first_topic = create(:topic, name: "first_topic", topic_group: shared_group)
        second_topic = create(:topic, name: "second_topic", topic_group: shared_group)
        review = create(:review)
        review.topics = [ first_topic, second_topic ]
        get admin_topic_groups_path
        expect(response.body).to include("使用 1 件")
        expect(response.body).not_to include("使用 2 件")
      end

      it "属する分野の数が少ない順に並ぶ（正常系）" do
        group_with_two_topics = create(:topic_group, name: "group_with_two_topics")
        create(:topic, name: "first_topic", topic_group: group_with_two_topics)
        create(:topic, name: "second_topic", topic_group: group_with_two_topics)
        group_with_one_topic = create(:topic_group, name: "group_with_one_topic")
        create(:topic, name: "only_topic", topic_group: group_with_one_topic)
        get admin_topic_groups_path
        expect(response.body.index("group_with_one_topic")).to be < response.body.index("group_with_two_topics")
      end

      it "分野の数が同じなら、グループ名の辞書順に並ぶ（正常系）" do
        later_in_alphabet_group = create(:topic_group, name: "later_in_alphabet_group")
        create(:topic, name: "topic_in_later_group", topic_group: later_in_alphabet_group)
        earlier_in_alphabet_group = create(:topic_group, name: "earlier_in_alphabet_group")
        create(:topic, name: "topic_in_earlier_group", topic_group: earlier_in_alphabet_group)
        get admin_topic_groups_path
        expect(response.body.index("earlier_in_alphabet_group")).to be < response.body.index("later_in_alphabet_group")
      end
    end
  end
end
