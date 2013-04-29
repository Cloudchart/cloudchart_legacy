require "spec_helper"

describe PersonsController do
  describe "index" do
    it "should return stored persons" do
      organization = create :organization
      person = create :person, organization: organization
      sign_in person.user
      
      get :index, { format: :json, organization_id: organization.id }
      body = parse_json(response.body)
      body.to_json.should be_json_eql({ persons: [person] }.to_json)
    end
  end
  
  describe "search" do
    it "should return search results for name" do
      organization = create :organization
      person = create :person, organization: organization
      person.index.refresh
      sign_in person.user
      
      get :search, { format: :json, organization_id: organization.id, search: { query: person.first_name } }
      body = parse_json(response.body)
      body.to_json.should be_json_eql({ persons: [person] }.to_json)
      
      person.destroy
    end
    
    it "should return search results for employer" do
      organization = create :organization
      person = create :person_with_work, organization: organization
      person.index.refresh
      other_person = create :person, work: person.work, organization: organization
      other_person.index.refresh
      sign_in person.user
      
      get :search, { format: :json, organization_id: organization.id, search: { query: person.employer } }
      body = parse_json(response.body)
      body.to_json.should be_json_eql({ persons: [person, other_person] }.to_json)
      
      person.destroy
      other_person.destroy
    end
    
    it "should return search results for name and employer" do
      organization = create :organization
      person = create :person_with_work, organization: organization
      person.index.refresh
      sign_in person.user
      
      get :search, { format: :json, organization_id: organization.id, search: { query: "#{person.first_name} #{person.employer}" } }
      body = parse_json(response.body)
      body.to_json.should be_json_eql({ persons: [person] }.to_json)
      
      person.destroy
    end
  end
  
  describe "show" do
    it "should return person" do
      organization = create :organization
      person = create :person, organization: organization
      sign_in person.user
      
      get :show, { format: :json, organization_id: organization.id, id: person.identifier }
      body = parse_json(response.body)
      body.to_json.should be_json_eql({ person: person }.to_json)
    end
  end
  
  describe "update" do
    it "should be able to mark person starred" do
      organization = create :organization
      person = create :person, organization: organization
      sign_in person.user
      
      put :update, { format: :json, organization_id: organization.id, id: person.identifier, person: { is_starred: true } }
      body = parse_json(response.body)
      body.to_json.should be_json_eql({ person: person.reload }.to_json)
      
      person.is_starred.should be_true
    end
  end
end
