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
      expected = {
        root_id: chart.id,
        ancestor_ids: chart.ancestor_ids,
        nodes: chart.descendant_and_ancestor_nodes,
        links: chart.descendant_links_and_self,
        identities: chart.descendant_identities_and_self
      }
      
      get :show, { format: :json, id: chart.id }
      body = parse_json(response.body)
      body.to_json.should be_json_eql(expected.to_json)
    end
  end
  
  describe "update" do
    it "should update nodes attributes" do
      chart = create_chart
      node1 = chart.create_nested_node(title: "Directors")
      node2 = node1.create_nested_node(title: "Developers")
      node3 = node1.create_nested_node(title: "Designers")
      
      expected = {
        root_id: chart.id,
        ancestor_ids: chart.ancestor_ids.as_json,
        nodes: chart.descendant_and_ancestor_nodes.as_json,
        links: chart.descendant_links_and_self.as_json,
        identities: chart.descendant_identities_and_self.as_json
      }
      
      # Modify node
      node = expected[:nodes].at(0)
      node["title"] = "Dummy chart text"
      node = expected[:nodes].at(1)
      node["title"] = "Dummy node text"
      
      # Delete node
      node = expected[:nodes].delete_at(2)
      expected[:links].delete_if { |link| link["child_node_id"] == node["id"] }
      
      # Add node
      node = Node.new(title: "Awesome node").as_json
      node["level"] = 1
      node["id"] = "_1"
      expected[:nodes] << node
      
      # Add link
      link = Link.new(parent_node_id: expected[:nodes].first["id"]).as_json
      link["id"] = "_1"
      link["child_node_id"] = "_1"
      expected[:links] << link
      
      # Update
      put :update, { format: :json, id: chart.id, node: {
        nodes: expected[:nodes],
        links: expected[:links],
        identities: expected[:identities]
      } }
      
      body = parse_json(response.body)
      body.to_json.should be_json_eql({}.to_json)
      
      # Check
      get :show, { format: :json, id: chart.id }
      body = parse_json(response.body)
      body.to_json.should be_json_eql(expected.to_json).excluding("child_node_id")
      
      chart.to_png!
      `open #{chart.picture.path}`
    end
  end
end
