require "spec_helper"

describe PersonsController do
  describe "search" do
    it "should return search results" do
      person = create :person, first_name: "Someone", last_name: "Else"
      person.index.refresh
      sign_in person.user
      
      get :search, { format: :json, q: "Someone" }
      body = parse_json(response.body)
      body.first.to_json.should be_json_eql(person.to_json)
      
      person.destroy
    end
  end
end
