class Review < ApplicationRecord
  belongs_to :user
  belongs_to :material

  has_many :review_topics, dependent: :destroy
  has_many :topics, through: :review_topics

  # フォームから受け取る「カンマ区切りの分野文字列」。DB カラムではない仮想属性。
  attr_accessor :topic_names

  # enumの定義
  enum :start_level, {
    complete_beginner: 1,  # 全くの初心者
    entry_level: 2,        # 入門レベル
    basic_level: 3,        # 基礎レベル
    intermediate_level: 4, # 中級レベル
    advanced_level: 5      # 上級レベル
  }, prefix: true

  enum :difficulty_rating, {
    very_easy: 1,      # とても優しい
    easy: 2,           # 優しい
    just_right: 3,     # ちょうどいい
    difficult: 4,      # 難しい
    very_difficult: 5  # とても難しい
  }, prefix: true

  # バリデーション
  validates :start_level, presence: true
  validates :difficulty_rating, presence: true
  validates :user_id, uniqueness: { scope: :material_id, message: "は同じ教材に対して1回のみ評価できます" }
end
