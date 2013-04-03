require "spec_helper"

describe Organization do
  it "should be able to render root nodes sctructure" do
    organization = create :organization
    chart = organization.nodes.create_chart_node(title: "Test")
    
    node1 = chart.create_nested_node(title: "Directors")
    node2 = chart.create_nested_node(title: "Developers")
    node3 = chart.create_nested_node(title: "Designers")
    
    chart.to_png!
    `open #{chart.picture.path}`
  end
  
  it "should be able to render linked nodes sctructure" do
    organization = create :organization
    chart = organization.nodes.create_chart_node(title: "Test")
    
    node1 = chart.create_nested_node(title: "Directors")
    node2 = node1.create_nested_node(title: "Developers")
    node3 = node1.create_nested_node(title: "Designers")
    
    chart.to_png!
    `open #{chart.picture.path}`
  end
  
  it "should be able to render nodes with identities" do
    organization = create :organization
    chart = organization.nodes.create_chart_node(title: "Test")
    
    node1 = chart.create_nested_node(title: "Directors")
    node2 = node1.create_nested_node(title: "Developers")
    node3 = node1.create_nested_node(title: "Designers")
    node4 = node3.create_nested_node(title: "Junior Designers")
    
    person1 = create :person, first_name: "Daria", last_name: "Nifontova"
    person2 = create :person, first_name: "Anton", last_name: "Outkine"
    person3 = create :person, first_name: "Eugene", last_name: "Kovalev"
    
    node2.identities.create!(person: person2)
    node2.identities.create!(person: person3)
    node3.identities.create!(person: person1)
    node3.identities.create!(person: person2)
    node4.identities.create!(person: person1)
    
    chart.to_png!
    `open #{chart.picture.path}`
  end
  
  it "should be able to render nodes with different identities" do
    organization = create :organization
    chart = organization.nodes.create_chart_node(title: "Test")
    
    node1 = chart.create_nested_node(title: "Directors")
    node2 = node1.create_nested_node(title: "Developers")
    node3 = node1.create_nested_node(title: "Designers")
    
    person1 = create :person, first_name: "Daria", last_name: "Nifontova"
    person2 = create :person, first_name: "Anton", last_name: "Outkine"
    
    node2.identities.create!(type: "vacancy", position: "Someone 1")
    node2.identities.create!(type: "vacancy", position: "Someone 2")
    node3.identities.create!(person: person1)
    node3.identities.create!(person: person2)
    
    chart.to_png!
    `open #{chart.picture.path}`
  end
  
  it "should be able to render nodes with different link types" do
    organization = create :organization
    chart = organization.nodes.create_chart_node(title: "Test")
    
    node1 = chart.create_nested_node(title: "Directors")
    node2 = node1.create_nested_node(title: "Developers")
    node3 = node1.create_nested_node(title: "Designers")
    node4 = node3.create_nested_node({ title: "Junior Designers" }, { type: "indirect" })
    
    chart.to_png!
    `open #{chart.picture.path}`
  end
  
  it "should be able to render subtree" do
    organization = create :organization
    chart = organization.nodes.create_chart_node(title: "Test")
    
    node1 = chart.create_nested_node(title: "Directors")
    node2 = node1.create_nested_node(title: "Developers")
    node3 = node1.create_nested_node(title: "Designers")
    
    node1.to_png!
    `open #{node1.picture.path}`
  end
  
  it "should correctly display levels" do
    organization = create :organization
    chart = organization.nodes.create_chart_node(title: "Test")
    
    node1 = chart.create_nested_node(title: "Directors")
    node2 = node1.create_nested_node(title: "Developers")
    node3 = node1.create_nested_node(title: "Designers")
    
    # Update titles
    chart.descendant_nodes.each { |x| x.set(:title, x.level.to_s) }
    
    chart.to_png!
    `open #{chart.picture.path}`
  end
end
