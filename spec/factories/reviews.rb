FactoryBot.define do
  factory :review do
    user
    material
    start_level { :complete_beginner }
    difficulty_rating { :just_right }
  end
end
