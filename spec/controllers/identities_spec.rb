require "spec_helper"

describe IdentitiesController do
  before do
    @user = create :user
    sign_in @user
  end
  
  describe "index" do
    it "should return stored persons" do
      organization = create :organization_with_owner, user: @user
      person = create :person, user: @user, organization: organization
      
      get :index, { format: :json, organization_id: organization.id }
      body = parse_json(response.body)
      body.to_json.should be_json_eql({ persons: [person] }.to_json)
    end
  end
  
  describe "show" do
    it "should return person" do
      organization = create :organization_with_owner, user: @user
      person = create :person, user: @user, organization: organization
      
      get :show, { format: :json, organization_id: organization.id, id: person.identifier }
      body = parse_json(response.body)
      body.to_json.should be_json_eql({ person: person }.to_json)
    end
  end
  
  describe "update" do
    it "should be able to mark person starred" do
      organization = create :organization_with_owner, user: @user
      person = create :person, user: @user, organization: organization
      identity = organization.identities.first
      
      put :update, { format: :json, organization_id: organization.id, id: person.identifier, person: { is_starred: true } }
      body = parse_json(response.body)
      body.to_json.should be_json_eql({ person: identity.reload.to_person }.to_json)
      
      identity.is_starred.should be_true
    end
  end
end
