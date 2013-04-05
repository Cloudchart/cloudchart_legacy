# TODO: Create indexes
class Node
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::Paperclip
  store_in collection: "nodes"
  
  # Scopes
  scope :charts, where(type: "chart")
  
  # Relations
  belongs_to :organization
  has_many :identities
  
  has_and_belongs_to_many :parents, class_name: "Node", inverse_of: nil
  has_and_belongs_to_many :left_links, class_name: "Link", inverse_of: nil
  has_and_belongs_to_many :right_links, class_name: "Link", inverse_of: nil
  
  # Fields
  field :title, type: String
  field :type, type: String
  
  # Validations
  validates :title, presence: true
  
  # Picture
  has_mongoid_attached_file :picture,
    styles: { preview: ["600x400>", :png] }
  
  # Callbacks
  before_save {
    self.parent_ids = [] if self.parent_ids.nil?
    self.left_link_ids = [] if self.left_link_ids.nil?
    self.right_link_ids = [] if self.right_link_ids.nil?
  }
  
  # Modify tree methods
  def create_nested_node(params, link_params = {})
    node = self.organization.nodes.where(params).create
    link = self.organization.links.where(link_params.merge({ left_node: self, right_node: node })).create
    node
  end
  
  def remove_parent
    self.organization.links.where(right_node: self).destroy_all
  end
  
  def ensure_parent(node, link_params = {})
    self.remove_parent
    self.organization.links.where(link_params.merge({ left_node: node, right_node: self })).create
  end
  
  # Select tree methods
  def children_nodes
    self.children_links.map(&:right_node)
  end
  
  def children_links
    self.left_links
  end
  
  def descendant_nodes
    Node.in(parent_ids: self.id)
  end
  
  def descendant_nodes_and_self
    [self] + descendant_nodes
  end
  
  def descendant_links
    Link.in(left_node_id: self.descendant_nodes.map(&:id))
  end
  
  def descendant_links_and_self
    Link.in(left_node_id: self.descendant_nodes_and_self.map(&:id))
  end
  
  def level
    self.parent_ids.count
  end
  
  # Output methods
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
      style: "filled",
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
          left_node = graph_nodes[link.left_node.id]
          right_node = graph_nodes[link.right_node.id]
          next if !left_node || !right_node
          
          graph.add_edges(left_node, right_node, dir: link.dir)
        end
      end
    end
end
