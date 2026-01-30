class Review < ApplicationRecord
  belongs_to :user
  belongs_to :material

  # enumの定義
  enum start_level: {
    complete_beginner: 1,  # 全くの初心者
    entry_level: 2,        # 入門レベル
    basic_level: 3,        # 基礎レベル
    intermediate_level: 4, # 中級レベル
    advanced_level: 5      # 上級レベル
  }, _prefix: true

  enum difficulty_rating: {
    very_easy: 1,      # とても優しい
    easy: 2,           # 優しい
    just_right: 3,     # ちょうどいい
    difficult: 4,      # 難しい
    very_difficult: 5  # とても難しい
  }, _prefix: true

  # バリデーション
  validates :start_level, presence: true
  validates :difficulty_rating, presence: true
  validates :user_id, uniqueness: { scope: :material_id, message: "は同じ教材に対して1回のみ評価できます" }
end
