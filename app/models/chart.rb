# coding: utf-8
class Chart
  include ActionView::Helpers::TextHelper
  include ApplicationHelper
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::Versioning
  include Mongoid::Paperclip
  include Mongoid::Slugify
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
  
  # Picture
  has_mongoid_attached_file :picture,
    styles: { preview: ["150x150#", :png] }
  
  # Versioning
  max_versions 100
  accepts_nested_attributes_for :versions
  
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
          node.parent = levels[level-1]
          node.save!
        end
      end
      
      # Clear image
      self.picture = nil
      self.save
    end
    
    self.to_xdot!
  }
  
  # Accessors
  attr_accessor :cached, :previous_text
  
  def serializable_hash(options)
    super (options || {}).merge(except: [:_id, :token, :is_demo, :picture_content_type, :picture_file_name, :picture_file_size, :picture_updated_at], methods: [:id, :nodes])
  end
  
  def slug_or_id
    self.slug || self.id
  end
  
  def to_png(style = nil)
    self.to_png! unless self.picture?
    self.picture.url(style)
  end
  
  def to_pdf
    to_graph.output(pdf: String)
  end
  
  def to_xdot
    self.to_xdot! if self.xdot.blank?
    self.xdot
  end
  
  def to_xdot_with_parent(node)
    xdot = to_graph(node).output(xdot: String)
    # Magically fix broken characters
    begin
      # xdot.encode!("utf-16", "utf-8", fallback: Proc.new { |x| "?" })
      xdot.encode!("utf-8")
    rescue
      xdot.encode!("utf-16", "utf-8", invalid: :replace, replace: "?")
      xdot.encode!("utf-8", "utf-16")
    end
    
    xdot
  end
  
  def to_text_with_parent(node)
    text = []
    node.traverse(:depth_first).map { |n|
      text << " " * n.depth + n.title
    }
    text.join("\n")
  end
  
  def prepare_text_with_parent(node, text)
    text.split("\n").map { |x| " " * node.depth + x }.join("\n")
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
    rescue Exception
      self.picture = nil
      self.picture_updated_at = Time.new
    end
  end
  
  def to_xdot!
    xdot = to_graph.output(xdot: String)
    # Magically fix broken characters
    begin
      # xdot.encode!("utf-16", "utf-8", fallback: Proc.new { |x| "?" })
      xdot.encode!("utf-8")
    rescue
      xdot.encode!("utf-16", "utf-8", invalid: :replace, replace: "?")
      xdot.encode!("utf-8", "utf-16")
    end
    
    self.set(:xdot, xdot)
    self.xdot
  end
  
  private
  
    def to_graph(parent = nil)
      GraphViz::new(:G, type: :digraph) { |g|
        # Create root node with chart name
        if parent
          root = g.add_nodes(parent.title, shape: "ellipse")
        else
          root = g.add_nodes(self.title, shape: "ellipse")
        end
        
        # Recursive add nodes
        self.cached = self.nodes.ordered.cache
        add_nodes(g, root, self.cached.select { |x| x.parent_id == (parent ? parent.id : nil) })
      }
    end
    
    def add_nodes(g, root, nodes)
      nodes.each do |n|
        # Add node to root
        node = g.add_nodes(breaking_word_wrap(n.title, 40), shape: "box", href: "javascript:App.chart.click('#{n.id}')")
        edge = g.add_edges(root, node, dir: "none")
        
        # Search for children
        children = self.cached.select { |x| x.parent_id == n.id }
        if children.any?
          add_nodes(g, node, children)
        end
      end
    end
    
    def generate_slug
      title.to_slug.normalize.to_s
    end
end