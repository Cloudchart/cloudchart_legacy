class Link
  include Mongoid::Document
  include Mongoid::Timestamps
  store_in collection: "links"
  
  # Scopes
  scope :ordered, order_by(:id.asc)
  default_scope ordered
  scope :unordered, -> { all.tap { |criteria| criteria.options.store(:sort, nil) } }
  
  # Relations
  belongs_to :organization, validate: true
  belongs_to :parent_node, class_name: "Node", inverse_of: nil, validate: true
  belongs_to :child_node, class_name: "Node", inverse_of: nil, validate: true
  
  # Fields
  attr_accessible :organization_id, :parent_node_id, :child_node_id, :type, :is_imaginary
  
  field :type, type: String, default: "direct"
  field :is_imaginary, type: Boolean, default: false
  
  # TODO: Indexes
  
  # Callbacks
  before_save { self.attach_link }
  before_destroy { self.detach_link }
  
  # Fields
  def serializable_hash(options)
    super (options || {}).merge(
      except: [:_id, :organization_id],
      methods: [:id]
    )
  end
  
  def type_enum
    %w(direct indirect)
  end
  
  # Representation
  def dir
    case self.type
    when "direct"
      "forward"
    when "indirect"
      "back"
    end
  end
  
  # Modify tree methods
  def ensure_attributes(params)
    self.detach_link
    self.update_attributes(params)
    self
  end
  
  def attach_link
    # Add link to nodes
    if !self.parent_node.parent_link_ids.include?(self.id)
      self.parent_node.add_to_set(:parent_link_ids, self.id)
    end
    
    if !self.child_node.child_link_ids.include?(self.id)
      self.child_node.add_to_set(:child_link_ids, self.id)
    end
    
    # Save parents to right node
    self.parent_node.reload
    self.child_node.set(:parent_ids, self.parent_node.parent_ids + [self.parent_node.id])
    self.child_node.reload
    
    # Add id to parent_ids
    self.parent_node.reload
    self.child_node.descendant_nodes_and_self.each do |node|
      (self.parent_node.parent_ids + [self.parent_node.id]).each do |id|
        node.add_to_set(:parent_ids, id)
      end
    end
    self.child_node.reload
  end
  
  def detach_link
    # Remove id from parent_ids
    self.child_node.descendant_nodes_and_self.each { |node| node.pull(:parent_ids, self.parent_node.id) }
    
    # Remove link from nodes
    self.parent_node.pull(:parent_link_ids, self.id)
    self.child_node.pull(:child_link_ids, self.id)
    
    self.parent_node.reload
    self.child_node.reload
    
    true
  end
end
