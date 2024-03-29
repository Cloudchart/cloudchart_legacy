require "spec_helper"

describe Organization do
  it "should be able to render root nodes sctructure" do
    chart = create_chart
    
    node1 = chart.create_nested_node(title: "Directors")
    node2 = chart.create_nested_node(title: "Developers")
    node3 = chart.create_nested_node(title: "Designers")
    
    chart.to_png!
    `open #{chart.picture.path}`
  end
  
  it "should be able to render linked nodes sctructure" do
    chart = create_chart
    
    node1 = chart.create_nested_node(title: "Directors")
    node2 = node1.create_nested_node(title: "Developers")
    node3 = node1.create_nested_node(title: "Designers")
    
    chart.to_png!
    `open #{chart.picture.path}`
  end
  
  it "should be able to render nodes with identities" do
    chart = create_chart
    
    node1 = chart.create_nested_node(title: "Directors")
    node2 = node1.create_nested_node(title: "Developers")
    node3 = node1.create_nested_node(title: "Designers")
    node4 = node3.create_nested_node(title: "Junior Designers")
    
    person1 = create :person, first_name: "Daria", last_name: "Nifontova"
    person2 = create :person, first_name: "Anton", last_name: "Outkine"
    person3 = create :person, first_name: "Eugene", last_name: "Kovalev"
    
    node2.identities.build.employee!(person2)
    node2.identities.build.employee!(person3)
    node3.identities.build.employee!(person1)
    node3.identities.build.employee!(person2)
    node4.identities.build.employee!(person1)
    
    chart.to_png!
    `open #{chart.picture.path}`
  end
  
  it "should be able to render nodes with different identities" do
    chart = create_chart
    
    node1 = chart.create_nested_node(title: "Directors")
    node2 = node1.create_nested_node(title: "Developers")
    node3 = node1.create_nested_node(title: "Designers")
    
    person1 = create :person, first_name: "Daria", last_name: "Nifontova"
    person2 = create :person, first_name: "Anton", last_name: "Outkine"
    vacancy1 = create :vacancy, title: "Someone 1"
    vacancy2 = create :vacancy, title: "Someone 2"
    
    node2.identities.build.vacancy!(vacancy1)
    node2.identities.build.vacancy!(vacancy2)
    node3.identities.build.employee!(person1)
    node3.identities.build.employee!(person2)
    
    chart.to_png!
    `open #{chart.picture.path}`
  end
  
  it "should be able to render nodes with different link types" do
    chart = create_chart
    
    node1 = chart.create_nested_node(title: "Directors")
    node2 = node1.create_nested_node(title: "Developers")
    node3 = node1.create_nested_node(title: "Designers")
    node4 = node3.create_nested_node({ title: "Junior Designers" }, { type: "indirect" })
    
    chart.to_png!
    `open #{chart.picture.path}`
  end
  
  it "should be able to render subtree" do
    chart = create_chart
    
    node1 = chart.create_nested_node(title: "Directors")
    node2 = node1.create_nested_node(title: "Developers")
    node3 = node1.create_nested_node(title: "Designers")
    
    node1.to_png!
    `open #{node1.picture.path}`
  end
  
  it "should correctly display levels" do
    chart = create_chart
    
    node1 = chart.create_nested_node(title: "Directors")
    node2 = node1.create_nested_node(title: "Developers")
    node3 = node1.create_nested_node(title: "Designers")
    
    # Update titles
    chart.descendant_nodes.each { |x| x.set(:title, x.level.to_s) }
    
    chart.to_png!
    `open #{chart.picture.path}`
  end
  
  it "should correctly rearrange parents" do
    chart = create_chart
    
    node1 = chart.create_nested_node(title: "Directors")
    node2 = node1.create_nested_node(title: "Developers")
    node3 = node1.create_nested_node(title: "Designers")
    node4 = node2.create_nested_node(title: "Junior Developers")
    node5 = node3.create_nested_node(title: "Junior Designers")
    
    chart.to_png!
    `open #{chart.picture.path}`
    
    # Rearrange
    node3.ensure_parent(node2)
    node4.remove_parent
    
    # Update titles
    chart.descendant_nodes.each { |x| x.set(:title, "#{x.title} (#{x.level})") }
    
    chart.to_png!
    `open #{chart.picture.path}`
  end
  
  it "should correctly display children" do
    chart = create_chart
    
    node1 = chart.create_nested_node(title: "Directors")
    node2 = node1.create_nested_node(title: "Developers")
    node3 = node1.create_nested_node(title: "Designers")
    node4 = node2.create_nested_node(title: "Junior Developers")
    node5 = node2.create_nested_node(title: "Senior Developers")
    node6 = node3.create_nested_node(title: "Junior Designers")
    node7 = node4.create_nested_node(title: "Very Nested Developers")
    
    # Update children titles
    node2.children_nodes.each { |x| x.set(:title, "#{x.title} (children)") }
    
    chart.to_png!
    `open #{chart.picture.path}`
  end
  
  it "should correctly display imaginary nodes" do
    chart = create_chart
    
    node1 = chart.create_nested_node(title: "Directors")
    node2 = node1.create_nested_node(title: "Developers")
    node3 = node1.create_nested_node(title: "Designers")
    node4 = node2.create_nested_node(title: "Junior Developers", type: "imaginary")
    node5 = node2.create_nested_node(title: "Senior Developers")
    node6 = node3.create_nested_node(title: "Junior Designers")
    node7 = node4.create_nested_node(title: "Very Nested Developers")
    
    chart.to_png!
    `open #{chart.picture.path}`
  end
  
  it "should correctly display imaginary nodes" do
    chart = create_chart
    
    node1 = chart.create_nested_node(title: "Directors")
    node2 = node1.create_nested_node(title: "Developers")
    node3 = node1.create_nested_node(title: "Designers")
    node4 = node2.create_nested_node({ title: "Junior Developers" }, { is_imaginary: true })
    node5 = node2.create_nested_node(title: "Senior Developers")
    node6 = node3.create_nested_node(title: "Junior Designers")
    node7 = node4.create_nested_node(title: "Very Nested Developers")
    
    chart.to_png!
    `open #{chart.picture.path}`
  end
end
