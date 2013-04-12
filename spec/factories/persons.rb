FactoryGirl.define do
  factory :person do
    organization
    user
    external_id { Faker.numerify("######") }
  end
end
