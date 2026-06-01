# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

# 初期 Topic を投入する。
# 既に同名の Topic が存在する場合は新規作成しない（find_or_create_by! による冪等性）。
%w[ruby rails javascript typescript react git docker sql html css linux database].each do |name|
  Topic.find_or_create_by!(name: name)
end

# 開発環境専用のサンプルデータ。
# おすすめ機能（MaterialRecommender）の動作確認を手入力なしで行うために投入する。
if Rails.env.development?
  DEV_PASSWORD = "password"

  # dev ログイン情報：user1@example.com 〜 user3@example.com（いずれも password）
  users = (1..3).map do |i|
    User.find_or_create_by!(email: "user#{i}@example.com") do |u|
      u.password = DEV_PASSWORD
      u.display_name = "user#{i}"
    end
  end
  user_1, user_2, user_3 = users

  # サンプル教材
  material_1 = Material.find_or_create_by!(title: "プロを目指す人のためのRuby入門") { |m| m.url = "https://example.com/ruby-book";   m.description = "Ruby 入門の定番" }
  material_2 = Material.find_or_create_by!(title: "現場で使えるRails")            { |m| m.url = "https://example.com/rails-book";  m.description = "Rails 実践ガイド" }
  material_3 = Material.find_or_create_by!(title: "JavaScript入門")             { |m| m.url = "https://example.com/js-book";     m.description = "JS の基礎" }
  material_4 = Material.find_or_create_by!(title: "Docker実践ガイド")           { |m| m.url = "https://example.com/docker-book"; m.description = "Docker の実践" }
  material_5 = Material.find_or_create_by!(title: "SQLアンチパターン") { |m| m.url = "https://example.com/sql-book"; m.description = "DB 設計の落とし穴" }

  ruby       = Topic.find_by!(name: "ruby")
  rails      = Topic.find_by!(name: "rails")
  javascript = Topic.find_by!(name: "javascript")

  # user_1 の興味を作る（ruby / rails）。material_1 は user_1 レビュー済み → おすすめから除外される
  review = Review.find_or_create_by!(user: user_1, material: material_1) do |r|
    r.start_level = :complete_beginner
    r.difficulty_rating = :just_right
  end
  review.topics = [ ruby, rails ]

  # material_2: user_2[ruby, rails] + user_3[ruby] → 一致 = 3 → おすすめ 1 位
  review = Review.find_or_create_by!(user: user_2, material: material_2) do |r|
    r.start_level = :intermediate_level
    r.difficulty_rating = :difficult
  end
  review.topics = [ ruby, rails ]

  review = Review.find_or_create_by!(user: user_3, material: material_2) do |r|
    r.start_level = :basic_level
    r.difficulty_rating = :just_right
  end
  review.topics = [ ruby ]

  # material_4: user_2[ruby] → 一致 = 1 → おすすめ 2 位
  review = Review.find_or_create_by!(user: user_2, material: material_4) do |r|
    r.start_level = :entry_level
    r.difficulty_rating = :easy
  end
  review.topics = [ ruby ]

  # material_3: user_3[javascript] → user_1 の興味と不一致 → おすすめに出ない
  review = Review.find_or_create_by!(user: user_3, material: material_3) do |r|
    r.start_level = :complete_beginner
    r.difficulty_rating = :very_easy
  end
  review.topics = [ javascript ]

  # material_5: レビューなし → おすすめに出ない
end
