FactoryGirl.define do
  factory :vacancy do
    title { Faker::Name.name }
  end
end
