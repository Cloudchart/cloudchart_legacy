require "spec_helper"

describe PersonsController do
  before do
    @user = create :user
    sign_in @user
  end
  
  describe "search" do
    it "should return search results for name" do
      organization = create :organization_with_owner, user: @user
      person = create :person, user: @user, organization: organization
      person.index.refresh
      
      get :search, { format: :json, search: { query: person.first_name } }
      body = parse_json(response.body)
      body.to_json.should be_json_eql({ persons: [person] }.to_json)
      
      person.destroy
    end
    
    it "should return search results for employer" do
      organization = create :organization_with_owner, user: @user
      person = create :person_with_work, user: @user, organization: organization
      person.index.refresh
      other_person = create :person, user: @user, organization: organization, work: person.work
      other_person.index.refresh
      
      get :search, { format: :json, search: { query: person.employer } }
      body = parse_json(response.body)
      body["persons"].to_json.should include_json(person.to_json)
      body["persons"].to_json.should include_json(other_person.to_json)
      
      person.destroy
      other_person.destroy
    end
    
    it "should return search results for name and employer" do
      organization = create :organization_with_owner, user: @user
      person = create :person_with_work, user: @user, organization: organization
      person.index.refresh
      sign_in person.user
      
      get :search, { format: :json, search: { query: "#{person.first_name} #{person.employer}" } }
      body = parse_json(response.body)
      body.to_json.should be_json_eql({ persons: [person] }.to_json)
      
      person.destroy
    end
  end
  
  # describe "update" do
  #   it "should be able to mark person starred" do
  #     organization = create :organization_with_owner, user: @user
  #     person = create :person, user: @user, organization: organization
  #     identity = organization.identities.first
  #     
  #     put :update, { format: :json, organization_id: organization.id, id: person.identifier, person: { is_starred: true } }
  #     body = parse_json(response.body)
  #     body.to_json.should be_json_eql({ person: identity.reload.to_person }.to_json)
  #     
  #     identity.is_starred.should be_true
  #   end
  # end
end
