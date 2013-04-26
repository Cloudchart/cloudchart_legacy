require "spec_helper"

describe NodesController do
  describe "index" do
    it "should return index without parameters" do
      chart = create_chart
      
      get :index, { format: :json, organization_id: chart.organization.id }
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
      
      get :show, { format: :json, organization_id: chart.organization.id, id: chart.id }
      body = parse_json(response.body)
      body.to_json.should be_json_eql(expected.to_json)
    end
    
    it "should return show for nested node" do
      chart = create_chart
      node1 = chart.create_nested_node(title: "Directors")
      node2 = node1.create_nested_node(title: "Developers")
      node3 = node1.create_nested_node(title: "Designers")
      node4 = node2.create_nested_node(title: "Junior Developers")
      node5 = node2.create_nested_node(title: "Middle Developers")
      node6 = node2.create_nested_node(title: "Senior Developers")
      
      expected = {
        root_id: node2.id,
        ancestor_ids: node2.ancestor_ids,
        nodes: node2.descendant_and_ancestor_nodes,
        links: node2.descendant_links_and_self,
        identities: node2.descendant_identities_and_self
      }
      
      get :show, { format: :json, organization_id: chart.organization.id, id: node2.id }
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
      node4 = node2.create_nested_node(title: "Junior Developers")
      node5 = node2.create_nested_node(title: "Middle Developers")
      node6 = node2.create_nested_node(title: "Senior Developers")
      node7 = node4.create_nested_node(title: "Ivan")
      node8 = node4.create_nested_node(title: "Nikolay")
      
      chart.to_png!
      `open #{chart.picture.path}`
      
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
      node = expected[:nodes].delete_at(3)
      expected[:links].delete_if { |link| link["child_node_id"] == node["id"] }
      
      # Add node
      node = Node.new(title: "Awesome node").as_json
      node["id"] = "_1"
      node["level"] = 1
      expected[:nodes] << node
      
      # Modify link
      link = expected[:links].at(4)
      node = expected[:nodes].at(5)
      link["parent_node_id"] = chart.id
      link["type"] = "indirect"
      node["level"] = 1
      
      # Delete link and add new one
      deleted = expected[:links].delete_at(3)
      node = expected[:nodes].at(4)
      link = Link.new(parent_node_id: expected[:nodes].first["id"]).as_json
      link["id"] = "_1"
      link["child_node_id"] = deleted["child_node_id"]
      node["level"] = 1
      expected[:links] << link
      
      # Add link
      link = Link.new(parent_node_id: expected[:nodes].first["id"]).as_json
      link["id"] = "_1"
      link["child_node_id"] = "_1"
      expected[:links] << link
      
      # Update
      put :update, { format: :json, organization_id: chart.organization.id, id: chart.id, node: {
        nodes: expected[:nodes],
        links: expected[:links],
        identities: expected[:identities]
      } }
      
      body = parse_json(response.body)
      body.to_json.should be_json_eql({}.to_json)
      response.status.should be_eql(200)
      
      # Check
      get :show, { format: :json, organization_id: chart.organization.id, id: chart.id }
      body = parse_json(response.body)
      body.to_json.should be_json_eql(expected.to_json).excluding("child_node_id")
      
      # Update titles and render
      chart.descendant_nodes.each { |x| x.set(:title, "#{x.title} (#{x.level})") }
      chart.to_png!
      `open #{chart.picture.path}`
    end
    
    it "should not update other nodes" do
      chart = create_chart
      node1 = chart.create_nested_node(title: "Directors")
      
      other_chart = create_chart
      node2 = other_chart.create_nested_node(title: "Other directors")
      
      expected = {
        root_id: chart.id,
        ancestor_ids: chart.ancestor_ids.as_json,
        nodes: chart.descendant_and_ancestor_nodes.as_json,
        links: chart.descendant_links_and_self.as_json,
        identities: chart.descendant_identities_and_self.as_json
      }
      
      # Modify other node
      node = node2.as_json
      node["title"] = "Dummy node text"
      expected[:nodes] << node
      
      # Update
      put :update, { format: :json, organization_id: chart.organization.id, id: chart.id, node: {
        nodes: expected[:nodes],
        links: expected[:links],
        identities: expected[:identities]
      } }
      
      body = parse_json(response.body)
      body.to_json.should be_json_eql({ errors: ["Node is invalid"] }.to_json)
      response.status.should be_eql(422)
    end
    
    it "should not create multiple links" do
      chart = create_chart
      node1 = chart.create_nested_node(title: "Directors")
      node2 = chart.create_nested_node(title: "Designers")
      
      expected = {
        root_id: chart.id,
        ancestor_ids: chart.ancestor_ids.as_json,
        nodes: chart.descendant_and_ancestor_nodes.as_json,
        links: chart.descendant_links_and_self.as_json,
        identities: chart.descendant_identities_and_self.as_json
      }
      
      # Add link
      link = Link.new(parent_node_id: expected[:nodes][1]["id"], child_node_id: expected[:nodes][2]["id"]).as_json
      link["id"] = "_1"
      expected[:links] << link
      
      # Update
      put :update, { format: :json, organization_id: chart.organization.id, id: chart.id, node: {
        nodes: expected[:nodes],
        links: expected[:links],
        identities: expected[:identities]
      } }
      
      body = parse_json(response.body)
      body.to_json.should be_json_eql({ errors: ["Link is invalid"] }.to_json)
      response.status.should be_eql(422)
    end
  end
end
