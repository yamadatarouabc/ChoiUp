require "rails_helper"

RSpec.describe TopicGroup, type: :model do
  describe "ファクトリ" do
    it "デフォルトで valid なオブジェクトを生成する" do
      expect(build(:topic_group)).to be_valid
    end
  end

  describe "name" do
    it "nil で invalid（presence 違反・異常系）" do
      topic_group = build(:topic_group, name: nil)
      expect(topic_group).not_to be_valid
    end

    it "重複した name で invalid（uniqueness 違反・異常系）" do
      create(:topic_group, name: "javascript")
      topic_group_with_same_name = build(:topic_group, name: "javascript")
      expect(topic_group_with_same_name).not_to be_valid
    end

    it "51 文字の name で invalid（length 境界・異常系）" do
      topic_group = build(:topic_group, name: "a" * 51)
      expect(topic_group).not_to be_valid
    end

    it "50 文字の name で valid（length 境界・正常系）" do
      topic_group = build(:topic_group, name: "a" * 50)
      expect(topic_group).to be_valid
    end
  end

  describe ".find_or_create_from_input" do
    context "正常系" do
      it "新規入力で TopicGroup を作成して返す" do
        expect {
          TopicGroup.find_or_create_from_input("javascript")
        }.to change(TopicGroup, :count).by(1)
      end

      it "既存と同じ入力で新規作成せず既存を返す" do
        existing_topic_group = create(:topic_group, name: "javascript")

        expect {
          expect(TopicGroup.find_or_create_from_input("javascript")).to eq(existing_topic_group)
        }.not_to change(TopicGroup, :count)
      end

      it "大文字を含む入力で既存 TopicGroup に寄せる（正規化）" do
        existing_topic_group = create(:topic_group, name: "javascript")
        expect(TopicGroup.find_or_create_from_input("JavaScript")).to eq(existing_topic_group)
      end

      it "前後に空白を含む入力で既存 TopicGroup に寄せる（正規化）" do
        existing_topic_group = create(:topic_group, name: "javascript")
        expect(TopicGroup.find_or_create_from_input("  javascript  ")).to eq(existing_topic_group)
      end
    end

    context "異常系（空入力）" do
      it "空文字で nil を返す" do
        expect(TopicGroup.find_or_create_from_input("")).to be_nil
      end

      it "空白のみの入力で nil を返す" do
        expect(TopicGroup.find_or_create_from_input("   ")).to be_nil
      end

      it "nil 入力で nil を返す" do
        expect(TopicGroup.find_or_create_from_input(nil)).to be_nil
      end
    end
  end

  describe "アソシエーション" do
    describe "has_many :topics" do
      it "紐づく topic を取得できる" do
        topic_group = create(:topic_group)
        topic = create(:topic, topic_group: topic_group)

        expect(topic_group.topics).to include(topic)
      end
    end
  end
end
