FactoryGirl.define do
  factory :organization do
    ignore do
      user false
    end
    
    title "Test Organization"
    
    factory :organization_with_owner do
      after(:create) do |organization, evaluator|
        evaluator.user.access!(organization, :owner!)
      end
    end
  end
end
