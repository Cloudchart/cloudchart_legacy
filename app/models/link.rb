# TODO: Change denormalized data on update
# TODO: Create indexes
class Link
  include Mongoid::Document
  store_in collection: "links"
  
  # Relations
  belongs_to :organization, validate: true
  belongs_to :left_node, class_name: "Node", inverse_of: nil, validate: true
  belongs_to :right_node, class_name: "Node", inverse_of: nil, validate: true
  
  # Fields
  field :type, type: String, default: "direct"
  
  # Callbacks
  before_save {
    # Add link to nodes
    if !self.left_node.left_link_ids.include?(self.id)
      self.left_node.add_to_set(:left_link_ids, self.id)
    end
    
    if !self.right_node.right_link_ids.include?(self.id)
      self.right_node.add_to_set(:right_link_ids, self.id)
    end
    
    # Save parents to right node
    self.left_node.reload
    self.right_node.set(:parent_ids, self.left_node.parent_ids + [self.left_node.id])
    self.right_node.reload
    
    true
  }
  
  before_destroy {
    # Remove link from nodes
    self.left_node.pull(:left_link_ids, self.id)
    self.right_node.pull(:right_link_ids, self.id)
    
    self.left_node.reload
    self.right_node.reload
    
    true
  }
  
  def type_enum
    %w(direct indirect)
  end
  
  def dir
    case self.type
    when "direct"
      "forward"
    when "indirect"
      "back"
    end
  end
end
