require "spec_helper"

describe NodesController do
  describe "index" do
    it "should return index without parameters" do
      chart = create_chart
      get :index, { format: :json }
      
      body = parse_json(response.body)
      body.first.to_json.should be_json_eql(chart.to_json)
    end
  end
  
  describe "show" do
    it "should return show for root node" do
      chart = create_chart
      get :show, { format: :json, id: chart.id }
      
      expected = {
        root_id: chart.id,
        ancestor_ids: chart.ancestor_ids,
        nodes: chart.descendant_and_ancestor_nodes,
        links: chart.descendant_links_and_self,
        identities: chart.descendant_identities_and_self
      }
      
      body = parse_json(response.body)
      body.to_json.should be_json_eql(expected.to_json)
    end
  end
  
  describe "update" do
    it "should update nodes attributes" do
      chart = create_chart
      put :update, { format: :json, id: chart.id, node: {
        nodes: chart.descendant_and_ancestor_nodes.as_json
      } }
      
      body = parse_json(response.body)
      body.to_json.should be_json_eql({}.to_json)
    end
  end
end
