require "spec_helper"

describe PersonsController do
  describe "index" do
    it "should return search results" do
      person = create :person, first_name: "Daria", last_name: "Nifontova"
      person.index.refresh
      sign_in person.user
      
      get :index, { format: :json, q: "Daria" }
      body = parse_json(response.body)
      body.first.to_json.should be_json_eql(person.to_json)
      
      person.destroy
    end
  end
end
