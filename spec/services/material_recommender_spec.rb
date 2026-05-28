require "rails_helper"

RSpec.describe MaterialRecommender do
  describe "#recommend" do
    context "正常系" do
      it "ユーザーの興味 topic と一致する review_topic を持つ未レビュー教材を返す" do
        user = create(:user)
        ruby = create(:topic, name: "ruby")

        # user が ruby topic でレビュー → user の興味が ruby になる
        reviewed_material = create(:material)
        user_review = create(:review, user: user, material: reviewed_material)
        user_review.topics << ruby

        # 他ユーザーが別の（user 未レビューの）教材に ruby topic でレビュー
        other_user = create(:user)
        unreviewed_material = create(:material)
        other_review = create(:review, user: other_user, material: unreviewed_material)
        other_review.topics << ruby

        expect(MaterialRecommender.new(user).recommend).to include(unreviewed_material)
      end

      it "既にレビュー済みの教材は除外される" do
        user = create(:user)
        ruby = create(:topic, name: "ruby")

        # user 自身が ruby topic でレビュー（興味は ruby と一致するが、既レビュー）
        reviewed_material = create(:material)
        user_review = create(:review, user: user, material: reviewed_material)
        user_review.topics << ruby

        expect(MaterialRecommender.new(user).recommend).not_to include(reviewed_material)
      end
      it "ユーザー topic と一致しない教材は返らない" do
        user = create(:user)
        ruby = create(:topic, name: "ruby")
        javascript = create(:topic, name: "javascript")

        # user の興味は ruby
        ruby_material = create(:material)
        user_review = create(:review, user: user, material: ruby_material)
        user_review.topics << ruby

        # 他ユーザーが javascript だけでレビューした教材（user の興味 ruby と不一致）
        other_user = create(:user)
        javascript_material = create(:material)
        other_user_review = create(:review, user: other_user, material: javascript_material)
        other_user_review.topics << javascript

        expect(MaterialRecommender.new(user).recommend).not_to include(javascript_material)
      end
      it "matched_review_topics_count の多い順にソートされる（三角測量）" do
        user = create(:user)
        ruby = create(:topic, name: "ruby")
        rails = create(:topic, name: "rails")

        # user の興味は ruby と rails
        user_material = create(:material)
        user_review = create(:review, user: user, material: user_material)
        user_review.topics << [ ruby, rails ]

        # material_a: 他ユーザーが ruby と rails でレビュー（マッチ 2）
        other_user_a = create(:user)
        material_a = create(:material)
        review_a = create(:review, user: other_user_a, material: material_a)
        review_a.topics << [ ruby, rails ]

        # material_b: 他ユーザーが ruby だけでレビュー（マッチ 1）
        other_user_b = create(:user)
        material_b = create(:material)
        review_b = create(:review, user: other_user_b, material: material_b)
        review_b.topics << ruby

        result = MaterialRecommender.new(user).recommend

        expect(result.to_a).to eq([ material_a, material_b ])
      end

      it "使用回数が Top-5 に入らない topic だけにマッチする教材は推薦されない（Top-N 絞り込み）" do
        user = create(:user)
        topics = (1..6).map { |i| create(:topic, name: "topic#{i}") }

        # user が material_1 に 6 topic 全部、material_2 に上位 5 topic を付ける
        # → topic1..5 は使用回数 2、topic6 は使用回数 1（最下位で Top-5 から外れる）
        material_1 = create(:material)
        create(:review, user: user, material: material_1).topics << topics
        material_2 = create(:material)
        create(:review, user: user, material: material_2).topics << topics[0..4]

        other_user = create(:user)

        # Top-5 内（topic1）にマッチする未レビュー教材 → 推薦される
        top5_topic_material = create(:material)
        create(:review, user: other_user, material: top5_topic_material).topics << topics[0]

        # Top-5 外（topic6）だけにマッチする未レビュー教材 → 推薦されない
        excluded_topic_material = create(:material)
        create(:review, user: other_user, material: excluded_topic_material).topics << topics[5]

        result = MaterialRecommender.new(user).recommend

        expect(result).to include(top5_topic_material)
        expect(result).not_to include(excluded_topic_material)
      end
    end

    context "異常系（履歴なし）" do
      it "topic 履歴がないユーザーには Material.none を返す" do
        user = create(:user)

        expect(MaterialRecommender.new(user).recommend).to be_empty
      end
    end

    context "limit の境界値" do
      it "limit: 9999 を渡しても MAX_LIMIT=50 件で打ち切られる（上限境界）" do
        user = create(:user)
        ruby = create(:topic, name: "ruby")

        # user の興味は ruby
        user_material = create(:material)
        user_review = create(:review, user: user, material: user_material)
        user_review.topics << ruby

        # 51 件の候補教材（他ユーザーが ruby でレビュー）を用意
        51.times do
          other_user_material = create(:material)
          other_user = create(:user)
          other_user_review = create(:review, user: other_user, material: other_user_material)
          other_user_review.topics << ruby
        end

        result = MaterialRecommender.new(user).recommend(limit: 9999)

        expect(result.to_a.size).to eq(MaterialRecommender::MAX_LIMIT)
      end
      it "limit: 0 を渡しても 1 件は返るスコープになる（下限境界）" do
        user = create(:user)
        ruby = create(:topic, name: "ruby")

        # user の興味は ruby
        user_material = create(:material)
        user_review = create(:review, user: user, material: user_material)
        user_review.topics << ruby

        # 候補を 2 件用意（1 件に絞られることを確認するため複数）
        2.times do
          other_user = create(:user)
          other_user_material = create(:material)
          other_user_review = create(:review, user: other_user, material: other_user_material)
          other_user_review.topics << ruby
        end

        expect(MaterialRecommender.new(user).recommend(limit: 0).to_a.size).to eq(1)
      end
      it "limit: -1 を渡しても 1 件は返るスコープになる（下限境界）" do
        user = create(:user)
        ruby = create(:topic, name: "ruby")

        # user の興味は ruby
        user_material = create(:material)
        user_review = create(:review, user: user, material: user_material)
        user_review.topics << ruby

        # 候補を 2 件用意（1 件に絞られることを確認するため複数）
        2.times do
          other_user = create(:user)
          other_user_material = create(:material)
          other_user_review = create(:review, user: other_user, material: other_user_material)
          other_user_review.topics << ruby
        end

        expect(MaterialRecommender.new(user).recommend(limit: -1).to_a.size).to eq(1)
      end
    end
  end
end
