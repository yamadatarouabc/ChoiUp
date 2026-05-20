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
