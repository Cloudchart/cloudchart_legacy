# TODO: Create indexes
class Node
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::Paperclip
  store_in collection: "nodes"
  
  # Scopes
  scope :charts, where(type: "chart")
  scope :roots, where(right_link_ids: [])
  
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
    styles: { preview: ["560x260>", :png] }
  
  # Callbacks
  before_save {
    self.parent_ids = [] if self.parent_ids.nil?
    self.left_link_ids = [] if self.left_link_ids.nil?
    self.right_link_ids = [] if self.right_link_ids.nil?
  }
  
  def create_nested_node(params, link_params = {})
    node = self.organization.nodes.where(params).create
    link = self.organization.links.where(link_params.merge({ left_node: self, right_node: node })).create
    
    node
  end
  
  def nested_nodes
    Node.in(parent_ids: self.id)
  end
  
  def nested_links
    Link.in(left_node_id: self.nested_nodes.map(&:id))
  end
  
  def level
    self.parent_ids.count
  end
  
  def to_png!
    begin
      io = Tempfile.new(['chart', '.png'])
      io.binmode
      timeout(10) { io.write to_graph.output(png: String) }
      io.close
      
      self.picture = File.open(io.path)
      self.save!
      
      io.unlink
    # rescue Exception
    #   self.picture = nil
    #   self.picture_updated_at = Time.new
    end
  end
  
  private
    
    def to_graph
      GraphViz::new(:G, type: :digraph) { |g|
        # Set background
        g.graph[:bgcolor] = "#ffffff00"
        g.graph[:truecolor] = true
        g.graph[:fontname] = "Helvetica"
        g.graph[:fontsize] = 12.0
        
        root = g.add_nodes(self.id.to_s,
          label: self.title,
          shape: "ellipse",
          style: "filled",
          fillcolor: "#ffffffff",
          fontname: "Helvetica",
          fontsize: 12.0
        )
        
        # Recursive add nodes
        add_nodes(g, root, self.nested_nodes.select { |x| x.parent_ids == self.parent_ids + [self.id] })
      }
    end
    
    def add_nodes(g, root, nodes)
      nodes.each do |n|
        add_node(g, root, n)
      end
    end
    
    def add_links(g, root, links)
      links.each do |l|
        add_node(g, root, l.right_node.reload, l)
      end
    end
    
    def add_node(g, root, n, l = nil)
      # Title
      title = n.title
      
      # Identities
      identities = n.identities
      if identities.any?
        title += "\n\n"
        title += identities.map(&:title).join("\n")
      end
      
      # Add node to root
      node = g.add_nodes(n.id.to_s,
        label: title,
        href: "javascript:App.chart.click('#{n.id}')",
        shape: "box",
        style: "filled",
        fillcolor: "#ffffffff",
        fontname: "Helvetica",
        fontsize: 12.0
      )
      edge = g.add_edges(root, node, dir: l ? l.dir_type : "none")
      
      # Render children nodes
      children = n.left_links
      if children.any?
        add_links(g, node, children)
      end
    end
end
