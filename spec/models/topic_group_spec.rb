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

  describe ".assign_topics!" do
    it "宣言に従って分野の所属グループが変わる" do
      javascript_group = create(:topic_group, name: "javascript")
      js = Topic.find_or_create_from_input("js")

      TopicGroup.assign_topics!("javascript", %w[js])

      expect(js.reload.topic_group).to eq(javascript_group)
    end

    it "宣言に書かれた分野が存在しなければ分野も作られてグループに属する" do
      expect {
        TopicGroup.assign_topics!("javascript", %w[ecmascript])
      }.to change(Topic, :count).by(1)

      expect(Topic.find_by(name: "ecmascript").topic_group.name).to eq("javascript")
    end

    it "2 回実行しても結果が同じ（冪等）" do
      TopicGroup.assign_topics!("javascript", %w[js javascript])
      topic_count = Topic.count
      topic_group_count = TopicGroup.count

      TopicGroup.assign_topics!("javascript", %w[js javascript])

      expect(Topic.count).to eq(topic_count)
      expect(TopicGroup.count).to eq(topic_group_count)
    end

    it "宣言に書かれていない分野は自分の名前のグループに属したまま変化しない" do
      ruby = Topic.find_or_create_from_input("ruby")

      TopicGroup.assign_topics!("javascript", %w[js javascript])

      expect(ruby.reload.topic_group.name).to eq("ruby")
    end
  end

  describe ".delete_unused!" do
    it "分野が 1 つも属していないグループが削除される" do
      unused_topic_group = create(:topic_group)

      expect { TopicGroup.delete_unused! }.to change(TopicGroup, :count).by(-1)
      expect(TopicGroup.exists?(unused_topic_group.id)).to be false
    end

    it "分野が属しているグループは削除されない" do
      topic_group = create(:topic_group)
      create(:topic, topic_group: topic_group)

      TopicGroup.delete_unused!

      expect(TopicGroup.exists?(topic_group.id)).to be true
    end

    it "2 回実行しても結果が同じ（冪等）" do
      create(:topic_group)
      TopicGroup.delete_unused!
      topic_group_count = TopicGroup.count

      TopicGroup.delete_unused!

      expect(TopicGroup.count).to eq(topic_group_count)
    end

    it "分野が属しているグループを直接削除しようとすると DB が拒否する（外部キーの restrict）" do
      topic_group = create(:topic_group)
      create(:topic, topic_group: topic_group)

      # on_delete: :restrict では PG::RestrictViolation が投げられ、
      # Rails はこれを ActiveRecord::StatementInvalid としてラップする。
      # （NO ACTION なら ActiveRecord::InvalidForeignKey になる）
      expect { topic_group.destroy }.to raise_error(ActiveRecord::StatementInvalid)
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
