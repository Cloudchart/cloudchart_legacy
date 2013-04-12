require "spec_helper"

describe PersonsController do
  describe "index" do
    it "should return search results" do
      chart = create_chart
      
      get :index, { format: :json }
      body = parse_json(response.body)
      body.first.to_json.should be_json_eql(chart.to_json)
    end
  end
end
