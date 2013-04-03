FactoryGirl.define do
  factory :person do
    external_id { Faker.numerify("######") }
  end
end
