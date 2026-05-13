require "rails_helper"

RSpec.describe ReviewTopic, type: :model do
  describe "ファクトリ" do
    it "デフォルトで valid なオブジェクトを生成する" do
      expect(build(:review_topic)).to be_valid
    end
  end

  describe "アソシエーション" do
    it "review が nil で invalid（belongs_to required・異常系）" do
      review_topic = build(:review_topic, review: nil)
      expect(review_topic).not_to be_valid
    end

    it "topic が nil で invalid（belongs_to required・異常系）" do
      review_topic = build(:review_topic, topic: nil)
      expect(review_topic).not_to be_valid
    end
  end

  describe "一意性制約（review_id と topic_id の組み合わせ）" do
    let(:review) { create(:review) }
    let(:topic) { create(:topic) }

    it "同一 review と 同一 topic の 2 件目は invalid（異常系）" do
      create(:review_topic, review: review, topic: topic)
      review_topic_with_same_review_and_topic = build(:review_topic, review: review, topic: topic)
      expect(review_topic_with_same_review_and_topic).not_to be_valid
    end
  end
end
