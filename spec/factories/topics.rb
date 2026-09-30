FactoryBot.define do
  factory :topic do
    sequence(:name) { |n| "topic#{n}" }
    topic_group { association :topic_group, name: name }
  end
end
