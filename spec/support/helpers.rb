def create_chart
  organization = create :organization
  organization.nodes.create_chart_node(title: "Test")
end

def create_chart_with_owner(user)
  organization = create :organization_with_owner, user: @user
  organization.nodes.create_chart_node(title: "Test")
end
