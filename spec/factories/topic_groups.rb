FactoryBot.define do
  factory :topic_group do
    sequence(:name) { |n| "group#{n}" }
  end
end
