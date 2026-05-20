require "rails_helper"

RSpec.describe Review, type: :model do
  describe "ファクトリ" do
    it "デフォルトで valid なオブジェクトを生成する" do
      expect(build(:review)).to be_valid
    end
  end

  describe "start_level" do
    it "nil で invalid（presence 違反・異常系）" do
      review = build(:review, start_level: nil)
      expect(review).not_to be_valid
    end

    it "想定の 5 段階が enum として定義されている" do
      expect(Review.start_levels.keys).to contain_exactly(
        "complete_beginner", "entry_level", "basic_level",
        "intermediate_level", "advanced_level"
      )
    end

    it "範囲外の値を代入すると ArgumentError（enum 違反・異常系）" do
      review = build(:review)
      expect { review.start_level = "unknown_level" }.to raise_error(ArgumentError)
    end
  end

  describe "difficulty_rating" do
    it "nil で invalid（presence 違反・異常系）" do
      review = build(:review, difficulty_rating: nil)
      expect(review).not_to be_valid
    end

    it "想定の 5 段階が enum として定義されている" do
      expect(Review.difficulty_ratings.keys).to contain_exactly(
        "very_easy", "easy", "just_right", "difficult", "very_difficult"
      )
    end

    it "範囲外の値を代入すると ArgumentError（enum 違反・異常系）" do
      review = build(:review)
      expect { review.difficulty_rating = "extreme" }.to raise_error(ArgumentError)
    end
  end

  describe "comment" do
    it "nil で valid（任意項目・正常系）" do
      review = build(:review, comment: nil)
      expect(review).to be_valid
    end

    it "空文字で valid（任意項目・正常系）" do
      review = build(:review, comment: "")
      expect(review).to be_valid
    end
  end

  describe "アソシエーション" do
    it "user が nil で invalid（belongs_to required・異常系）" do
      review = build(:review, user: nil)
      expect(review).not_to be_valid
    end

    it "material が nil で invalid（belongs_to required・異常系）" do
      review = build(:review, material: nil)
      expect(review).not_to be_valid
    end
  end

  describe "topics アソシエーション（has_many :through :review_topics）" do
    it "review.topics に Topic を代入すると関連が引ける（正常系）" do
      review = create(:review)
      topic1 = create(:topic)
      topic2 = create(:topic)
      review.topics = [ topic1, topic2 ]
      expect(review.reload.topics).to contain_exactly(topic1, topic2)
    end

    it "review を destroy すると紐づく review_topics も destroy される（dependent: :destroy）" do
      review = create(:review)
      topic1 = create(:topic)
      review.topics = [ topic1 ]
      expect { review.destroy }.to change(ReviewTopic, :count).by(-1)
    end
    it "同じ Topic を 2 回紐づけようとすると複合 unique で 2 件目は無効（境界・異常系）" do
      review = create(:review)
      topic1 = create(:topic)
      review.review_topics.create!(topic: topic1)
      second_review_topic = review.review_topics.build(topic: topic1)
      expect(second_review_topic).not_to be_valid
      expect(second_review_topic.errors[:review_id]).to be_present
    end
  end

  describe "一意性制約（user_id と material_id の組み合わせ）" do
    let(:user) { create(:user) }
    let(:material) { create(:material) }

    it "同一 user と 同一 material の 2 件目は invalid（異常系）" do
      create(:review, user: user, material: material)
      review_with_same_user_and_material = build(:review, user: user, material: material)
      expect(review_with_same_user_and_material).not_to be_valid
      expect(review_with_same_user_and_material.errors[:user_id]).to include(a_string_including("同じ教材に対して1回のみ評価できます"))
    end

    it "同一 user でも material が異なれば valid（正常系）" do
      create(:review, user: user, material: material)
      review_with_different_material = build(:review, user: user, material: create(:material))
      expect(review_with_different_material).to be_valid
    end

    it "同一 material でも user が異なれば valid（正常系）" do
      create(:review, user: user, material: material)
      review_with_different_user = build(:review, user: create(:user), material: material)
      expect(review_with_different_user).to be_valid
    end
  end
end
