FactoryGirl.define do
  factory :person do
    user
    type { ["Linkedin", "Facebook"].sample }
    external_id { Faker.numerify("######") }
    first_name { Faker::Name.name.split(" ").first }
    last_name { Faker::Name.name.split(" ").last }
    
    factory :person_with_work do
      work [{
        employer_id: Faker.numerify("###"),
        employer_name: Faker::Name.name,
        position: Faker::Name.name
      }.stringify_keys]
    end
  end
end
