require "spec_helper"

describe PersonsController do
  describe "index" do
    it "should return stored persons" do
      person = create :person, first_name: "Who", last_name: "Is it"
      sign_in person.user
      
      get :index, { format: :json }
      body = parse_json(response.body)
      body.to_json.should be_json_eql({ persons: [person] }.to_json)
    end
  end
  
  describe "search" do
    it "should return search results" do
      person = create :person, first_name: "Someone", last_name: "Else"
      person.index.refresh
      sign_in person.user
      
      get :search, { format: :json, search: { q: "Someone" } }
      body = parse_json(response.body)
      body.to_json.should be_json_eql({ persons: [person] }.to_json)
      
      person.destroy
    end
  end
end
