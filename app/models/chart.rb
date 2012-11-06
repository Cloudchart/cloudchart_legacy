# coding: utf-8
class Chart
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::Token
  store_in collection: "charts"
  
  # Scopes
  scope :ordered, order_by(:created_at.desc)
  scope :unordered, -> { all.tap { |criteria| criteria.options.store(:sort, nil) } }
  scope :demo, ordered.where(is_demo: true)
  
  # Relations
  belongs_to :user
  has_many :nodes, dependent: :destroy
  
  # Fields
  field :is_demo,   type: Boolean, default: false
  field :title,     type: String
  field :text,      type: String
  field :xdot,      type: String
  
  # Validations
  validates :title, presence: true
  
  # Token
  token length: 16
  
  # Indexes
  ## Ordered
  index({ user_id: 1, created_at: 1 })
  ## Demo
  index({ user_id: 1, is_demo: 1, created_at: 1 })
  
  # Callbacks
  before_save {
    if self.text_changed?
      # Destroy all nodes
      self.nodes.destroy_all
      
      # Parse lines
      lines = self.text.split("\r\n")
      levels = {}
      lines.each do |line|
        # Skip empty lines
        line.rstrip!
        next unless line.present?
        
        # Create node
        node = self.nodes.create(title: line.strip)
        
        # Calculate current level
        level = line[/([\s]*)/, 1].length
        levels[level] = node
        
        # Set parent
        if levels[level-1].present?
          node.set(:parent_id, levels[level-1].id)
        end
      end
    end
    
    self.to_xdot!
  }
  
  # Accessors
  attr_accessor :cached
  
  def serializable_hash(options)
    super (options || {}).merge(except: [:_id, :nodes, :token, :is_demo], methods: [:id])
  end
  
  def to_xdot!
    self.set(:xdot, to_graph.output(xdot: String).force_encoding("utf-8"))
    self.xdot
  end
  
  def to_xdot
    self.to_xdot! if self.xdot.blank?
    self.xdot
  end
  
  def to_pdf
    to_graph.output(pdf: String)
  end
  
  private
  
    def to_graph
      GraphViz::new(:G, type: :digraph) { |g|
        # Create root node with chart name
        root = g.add_nodes(self.title, shape: "ellipse")
        
        # Recursive add nodes
        self.cached = self.nodes.cache
        add_nodes(g, root, self.cached.select { |x| x.parent_id.nil? })
      }
    end
    
    def add_nodes(g, root, nodes)
      nodes.each do |n|
        # Add node to root
        node = g.add_nodes(n.title, shape: "box", href: "javascript:alert('#{n.title}')")
        edge = g.add_edges(root, node, dir: "none")
        
        # Search for children
        children = self.cached.select { |x| x.parent_id == n.id }
        if children.any?
          add_nodes(g, node, children)
        end
      end
    end
end