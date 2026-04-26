FactoryBot.define do
  factory :material do
    sequence(:title) { |n| "教材#{n}" }
    sequence(:url) { |n| "https://example.com/material/#{n}" }
    description { "教材の説明" }
  end
end
