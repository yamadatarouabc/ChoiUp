require "rails_helper"

RSpec.describe Topic, type: :model do
  describe "ファクトリ" do
    it "デフォルトで valid なオブジェクトを生成する" do
      expect(build(:topic)).to be_valid
    end
  end

  describe "name" do
    it "nil で invalid（presence 違反・異常系）" do
      topic = build(:topic, name: nil)
      expect(topic).not_to be_valid
    end

    it "重複した name で invalid（uniqueness 違反・異常系）" do
      create(:topic, name: "ruby")
      topic_with_same_name = build(:topic, name: "ruby")
      expect(topic_with_same_name).not_to be_valid
    end

    it "51 文字の name で invalid（length 境界・異常系）" do
      topic = build(:topic, name: "a" * 51)
      expect(topic).not_to be_valid
    end

    it "50 文字の name で valid（length 境界・正常系）" do
      topic = build(:topic, name: "a" * 50)
      expect(topic).to be_valid
    end
  end

  describe ".find_or_create_from_input" do
    context "正常系" do
      it "新規入力で Topic を作成して返す" do
        expect {
          Topic.find_or_create_from_input("ruby")
        }.to change(Topic, :count).by(1)
      end

      it "大文字を含む入力で既存 Topic に寄せる（正規化）" do
        existing_topic = create(:topic, name: "ruby")
        expect(Topic.find_or_create_from_input("Ruby")).to eq(existing_topic)
      end

      it "前後に空白を含む入力で既存 Topic に寄せる（正規化）" do
        existing_topic = create(:topic, name: "ruby")
        expect(Topic.find_or_create_from_input("  ruby  ")).to eq(existing_topic)
      end
    end

    context "グループの紐付け" do
      it "新規入力で同名のグループも作られて紐づく" do
        topic = Topic.find_or_create_from_input("ruby")
        expect(topic.topic_group.name).to eq("ruby")
      end

      it "同名のグループが既にあれば、グループは増えず、分野はそのグループに属する" do
        existing_topic_group = create(:topic_group, name: "ruby")

        expect {
          expect(Topic.find_or_create_from_input("ruby").topic_group).to eq(existing_topic_group)
        }.not_to change(TopicGroup, :count)
      end

      it "大文字を含む入力でも正規化された名前のグループに属する" do
        topic = Topic.find_or_create_from_input("Ruby")
        expect(topic.topic_group.name).to eq("ruby")
      end

      it "前後に空白を含む入力でも正規化された名前のグループに属する" do
        topic = Topic.find_or_create_from_input("  ruby  ")
        expect(topic.topic_group.name).to eq("ruby")
      end
    end

    context "異常系（空入力）" do
      it "空文字で nil を返す" do
        expect(Topic.find_or_create_from_input("")).to be_nil
      end

      it "空白のみの入力で nil を返す" do
        expect(Topic.find_or_create_from_input("   ")).to be_nil
      end

      it "nil 入力で nil を返す" do
        expect(Topic.find_or_create_from_input(nil)).to be_nil
      end

      it "空文字ではグループも作られない" do
        expect {
          Topic.find_or_create_from_input("")
        }.not_to change(TopicGroup, :count)
      end

      it "空白のみの入力ではグループも作られない" do
        expect {
          Topic.find_or_create_from_input("   ")
        }.not_to change(TopicGroup, :count)
      end

      it "nil 入力ではグループも作られない" do
        expect {
          Topic.find_or_create_from_input(nil)
        }.not_to change(TopicGroup, :count)
      end
    end
  end

  describe "アソシエーション" do
    describe "has_many :reviews, through: :review_topics" do
      it "中間レコード（review_topic）経由で関連 review を取得できる" do
        topic = create(:topic)
        review = create(:review)
        create(:review_topic, topic: topic, review: review)

        expect(topic.reviews).to include(review)
      end
    end

    describe "dependent: :destroy" do
      it "topic 削除時に紐づく review_topics も削除される" do
        topic = create(:topic)
        review = create(:review)
        create(:review_topic, topic: topic, review: review)

        expect { topic.destroy }.to change(ReviewTopic, :count).by(-1)
      end
    end
  end
end
