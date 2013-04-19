class Node
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::Paperclip
  store_in collection: "nodes"
  
  # Constants
  NEW_ID_REGEX = /^_[0-9]+$/
  
  # Scopes
  scope :ordered, order_by(:id.asc)
  default_scope ordered
  scope :unordered, -> { all.tap { |criteria| criteria.options.store(:sort, nil) } }
  scope :charts, where(type: "chart")
  
  # Relations
  belongs_to :organization
  has_many :identities
  
  has_and_belongs_to_many :parents, class_name: "Node", inverse_of: nil
  has_and_belongs_to_many :parent_links, class_name: "Link", inverse_of: nil
  has_and_belongs_to_many :child_links, class_name: "Link", inverse_of: nil
  
  # Fields
  attr_accessor :params
  attr_accessible :organization_id, :type, :title
  attr_accessible :title, as: :modify
  field :type, type: String
  field :title, type: String
  
  # Validations
  validates :title, presence: true
  
  # TODO: Indexes
  
  # Picture
  has_mongoid_attached_file :picture,
    styles: { preview: ["600x400>", :png] }
  
  # Callbacks
  before_save {
    self.parent_ids = [] if self.parent_ids.nil?
    self.parent_link_ids = [] if self.parent_link_ids.nil?
    self.child_link_ids = [] if self.child_link_ids.nil?
  }
  
  before_destroy {
    self.child_links.delete_all
    self.descendant_links_and_self.delete_all
    self.descendant_nodes.delete_all
  }
  
  # Callbacks for params
  before_validation :check_params
  before_save :save_params
  
  # Fields
  def serializable_hash(options)
    super (options || {}).merge(
      except: [
        :_id, :organization_id, :parent_ids, :parent_link_ids, :child_link_ids,
        :picture_content_type, :picture_file_name, :picture_file_size, :picture_updated_at
      ],
      methods: [:id, :level]
    )
  end
  
  def type_enum
    %w(chart imaginary)
  end
  
  def chart?
    self.type == "chart"
  end
  
  def imaginary?
    self.type == "imaginary"
  end
  
  # Modify tree methods
  def prepare_params(params)
    self.params = params
  end
  
  def check_params
    return true unless self.params
    
    # Check all nodes rights
    node_ids = self.params[:nodes].map { |attributes| attributes[:id] }.reject { |id| id =~ NEW_ID_REGEX }
    wrong_nodes = Node.in(id: node_ids).select { |node| node.organization_id != self.organization_id }
    self.errors.add(:base, :node_invalid) and return if wrong_nodes.any?
    
    # Check all links rights
    link_ids = self.params[:links].map { |attributes| attributes[:id] }.reject { |id| id =~ NEW_ID_REGEX }
    wrong_links = Link.in(id: link_ids).select { |link| link.organization_id != self.organization_id }
    self.errors.add(:base, :link_invalid) and return if wrong_links.any?
    
    # Check links uniqueness
    child_link_counts = self.params[:links].group_by { |link| link[:child_node_id] }.values.map(&:count)
    self.errors.add(:base, :link_invalid) and return if child_link_counts.select { |x| x > 1 }.any?
  end
  
  def save_params
    return true unless self.params
    
    # Ids mapping
    mapping = {}
    
    # Update nodes
    nodes = params[:nodes] || []
    node_ids = []
    nodes.each do |attributes|
      if attributes[:id] =~ NEW_ID_REGEX
        node = self.organization.nodes.create!(attributes)
        mapping[attributes[:id]] = node.id
      else
        node = Node.find(attributes[:id])
        node.ensure_attributes(attributes)
      end
      
      node_ids << node.id if node
    end
    
    # Remove nodes
    previous_node_ids = self.descendant_and_ancestor_nodes.map(&:id)
    Node.in(id: (previous_node_ids - node_ids)).destroy_all
    
    # Update links
    links = params[:links] || []
    link_ids = []
    links.each do |attributes|
      if attributes[:id] =~ NEW_ID_REGEX
        # Normalize attributes
        [:parent_node_id, :child_node_id].each do |attribute|
          if attributes[attribute] =~ NEW_ID_REGEX
            attributes[attribute] = mapping[attributes[attribute]]
          end
        end
        
        link = self.organization.links.create(attributes)
      else
        link = Link.find(attributes[:id])
        link.ensure_attributes(attributes)
      end
      
      link_ids << link.id if link
    end
    
    # Remove links
    previous_link_ids = self.descendant_links_and_self.map(&:id)
    Link.in(id: (previous_link_ids - link_ids)).destroy_all
    
    # Clear params
    self.params = nil
  end
  
  def ensure_attributes(params)
    self.update_attributes(sanitize_for_mass_assignment(params, :modify))
    self
  end
  
  def create_nested_node(params, link_params = {})
    node = self.organization.nodes.where(params).create
    link = self.organization.links.where(link_params.merge({ parent_node: self, child_node: node })).create
    node
  end
  
  def remove_parent
    self.organization.links.where(child_node: self).destroy_all
  end
  
  def ensure_parent(node, link_params = {})
    self.remove_parent
    self.organization.links.where(link_params.merge({ parent_node: node, child_node: self })).create
  end
  
  # Select tree methods
  def serialized_params
    { 
      root_id: self.id,
      ancestor_ids: self.ancestor_ids,
      nodes: self.descendant_and_ancestor_nodes,
      links: self.descendant_links_and_self,
      identities: self.descendant_identities_and_self
    }
  end
  
  def ancestor_ids
    self.parent_ids
  end
  
  def ancestor_nodes
    Node.in(id: self.parent_ids)
  end
  
  def children_nodes
    self.children_links.map(&:child_node)
  end
  
  def children_links
    self.parent_links
  end
  
  def descendant_nodes
    Node.in(parent_ids: self.id)
  end
  
  def descendant_nodes_and_self
    [self] + self.descendant_nodes
  end
  
  def descendant_and_ancestor_nodes
    (self.ancestor_nodes + [self] + self.descendant_nodes).uniq
  end
  
  def descendant_links
    Link.in(parent_node_id: self.descendant_nodes.map(&:id))
  end
  
  def descendant_links_and_self
    Link.in(parent_node_id: self.descendant_nodes_and_self.map(&:id))
  end
  
  def descendant_identities
    Identity.in(node_id: self.descendant_nodes.map(&:id))
  end
  
  def descendant_identities_and_self
    Identity.in(node_id: self.descendant_nodes_and_self.map(&:id))
  end
  
  def descendant_persons
    Person.in(id: self.descendant_identities.map(&:person_id).compact.uniq)
  end
  
  def descendant_persons_and_self
    Person.in(id: self.descendant_identities_and_self.map(&:person_id).compact.uniq)
  end
  
  def level
    self.parent_ids.count
  end
  
  # Representation
  def to_png!
    io = Tempfile.new(['chart', '.png'])
    
    begin
      io.binmode
      timeout(10) { io.write to_graph.output(png: String) }
      io.close
      
      self.picture = File.open(io.path)
      self.save!
    # rescue
    #   self.picture = nil
    #   self.picture_updated_at = Time.new
    ensure
      io.unlink
    end
  end
  
  def to_graph_node(graph)
    # Title
    title = self.title
    
    # Identities
    identities = self.identities
    if identities.any?
      title += "\n\n"
      title += identities.map(&:title).join("\n")
    end
    
    # Graph node
    graph.add_nodes(self.id.to_s, {
      label: title,
      href: "javascript:App.chart.click('#{self.id.to_s}')",
      shape: "box",
      style: self.imaginary? ? "invisible" : "filled",
      fillcolor: "#ffffffff",
      fontname: "Helvetica",
      fontsize: 12.0
    })
  end
  
  private
    
    def to_graph
      GraphViz::new(:G, type: :digraph) do |graph|
        # Set background
        graph.graph[:bgcolor] = "#ffffff00"
        graph.graph[:truecolor] = true
        graph.graph[:fontname] = "Helvetica"
        graph.graph[:fontsize] = 12.0
        
        # Add nodes
        graph_nodes = Hash[self.descendant_nodes_and_self.map do |node|
          [node.id, node.to_graph_node(graph)]
        end]
        
        # Add links
        self.descendant_links_and_self.each do |link|
          parent_node = graph_nodes[link.parent_node.id]
          child_node = graph_nodes[link.child_node.id]
          next if !parent_node || !child_node
          
          graph.add_edges(parent_node, child_node, dir: link.dir)
        end
      end
    end
end
