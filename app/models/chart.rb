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
  scope :ordered, order_by(:updated_at.desc)
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
  field :persons,   type: Hash, default: {}
  field :sidebar,   type: Integer, default: 400
  
  # Validations
  validates :title, presence: true
  
  # Token
  token length: 16
  
  # Indexes
  ## Slug
  index({ slug: 1, _id: 1 })
  ## Ordered
  index({ user_id: 1, updated_at: 1 })
  ## Demo
  index({ is_demo: 1, updated_at: 1 })
  
  # Picture
  has_mongoid_attached_file :picture,
    styles: { preview: ["560x260>", :png] }
  
  # Versioning
  max_versions 100
  accepts_nested_attributes_for :versions
  
  # Callbacks
  before_save {
    if self.text_changed?
      # Destroy all nodes
      self.nodes.destroy_all
    end
    
    if self.text_changed? && self.text.present?
      # Find all persons
      if self.user
        mentions = self.text.scan(/@([^\(]+)\(ln\:([^\)]+)\)/)
        client = self.user.linkedin_client
        mentions.delete_if { |x| self.persons[x[1]].is_a?(Hash) }.each { |x|
          self.persons[x[1]] = client.profile(id: x[1], fields: "id,first-name,last-name,picture-url,headline".split(","))
        }
      end
      
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
        level = line[/([\t]*)/, 1].length
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
    super (options || {}).merge(
      except: [:_id, :token, :is_demo, :picture_content_type, :picture_file_name, :picture_file_size, :picture_updated_at, :persons, :versions],
      methods: [:id, :nodes_as_hash]
    )
  end
  
  def slug_or_id
    self.slug || self.id
  end
  
  def nodes_as_hash
    Hash[self.nodes.map { |x| [x.id, x] }]
  end
  
  def demo?
    self.is_demo
  end
  
  def restore_from_version!(version)
    version = self.versions.where(version: version).first
    return unless version
    
    [:title, :text].each do |field|
      self.send("#{field}=", version.send(field))
    end
    
    self.save!
  end
  
  def create_from_version!(version)
    version = self.versions.where(version: version).first
    return unless version
    
    chart = self.user.charts.create(title: self.title)
    [:text].each do |field|
      chart.send("#{field}=", version.send(field))
    end
    
    chart.save!
    chart
  end
  
  def to_png(style = nil)
    self.to_png! unless self.picture?
    self.picture.url(style)
  end
  
  def to_pdf(node = nil)
    to_graph(node).output(pdf: String)
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
  
  def persons_with_parent(node)
    cached!
    self.class.find_persons(node.children)
  end
  
  def to_text_with_parent(node)
    text = []
    node.descendants.each { |n|
      next if n == node
      text << "\t" * (n.depth - node.depth - 1) + n.title
    }
    text.join("\n")
  end
  
  def prepare_text_with_parent(node, text)
    text.split("\n").map { |x| "\t" * (node.depth + 1) + x }.join("\n")
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
  
  def load_person(title)
    match = title.scan(/@([^\(]+)\(ln\:([^\)]+)\)/).first
    if self.user && match
      client = self.user.linkedin_client
      client.profile(id: match[1], fields: "id,first-name,last-name,picture-url,headline,summary,site-standard-profile-request".split(","))
    end
  end
  
  def find_person(title)
    match = title.scan(/@([^\(]+)\(ln\:([^\)]+)\)/).first
    self.persons[match[1]] if match
  end
  
  def find_person_title(title)
    person = self.find_person(title)
    if person
      "#{person["first_name"]} #{person["last_name"]}"
    else
      title
    end
  end
  
  def self.find_persons(nodes)
    nodes.select { |x| x.title =~ /^@/ }
  end
  
  def self.find_nodes(nodes)
    nodes.select { |x| x.title =~ /^[^@]/ }
  end
  
  private
    
    def cached!(nodes = nil)
      return self.cached if !self.cached.nil? && !nodes
      self.cached = nodes || self.nodes.ordered.cache
    end
    
    def to_graph(parent = nil)
      GraphViz::new(:G, type: :digraph) { |g|
        # Set background
        g.graph[:bgcolor] = "#ffffff00"
        g.graph[:truecolor] = true
        g.graph[:fontname] = "Helvetica"
        g.graph[:fontsize] = 12.0
        
        # Find nodes
        cached!
        
        # Create root node with chart name
        if parent
          root = g.add_nodes(parent.id.to_s,
            label: parent.title,
            shape: "ellipse",
            style: "filled",
            fillcolor: "#ffffffff",
            fontname: "Helvetica",
            fontsize: 12.0
          )
          
          cached!(self.class.find_nodes(self.cached))
        else
          root = g.add_nodes(self.id.to_s,
            label: self.title,
            shape: "ellipse",
            style: "filled",
            fillcolor: "#ffffffff",
            fontname: "Helvetica",
            fontsize: 12.0
          )
        end
        
        # Recursive add nodes
        add_nodes(g, root, self.cached.select { |x| x.parent_id == (parent ? parent.id : nil) })
      }
    end
    
    def add_nodes(g, root, nodes)
      nodes.each do |n|
        title = breaking_word_wrap(find_person_title(n.title), 40)
        
        # Find nested people
        people = self.class.find_persons(self.cached.select { |x| x.parent_id == n.id })
        if people.any?
          names = people.map { |x| breaking_word_wrap(find_person_title(x.title), 40) }
          title = "#{title}\n#{names.each_slice(3).map { |sliced| sliced.join(', ') }.join('\n')}"
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
        edge = g.add_edges(root, node, dir: "none")
        
        # Search for children
        children = self.class.find_nodes(self.cached.select { |x| x.parent_id == n.id })
        if children.any?
          add_nodes(g, node, children)
        end
      end
    end
    
    def assign_slug?
      self.title.blank? || self.title_changed?
    end
    
    def generate_slug
      self.title.to_slug.normalize.to_s
    end
end