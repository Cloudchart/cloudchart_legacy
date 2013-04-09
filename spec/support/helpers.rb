def create_chart
  organization = create :organization
  chart = organization.nodes.create_chart_node(title: "Test")
end
