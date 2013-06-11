class Organization
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::Paperclip
  store_in collection: "organizations"
  
  # Relations
  has_many :nodes, dependent: :destroy do
    def create_chart_node(params)
      charts.where(params).create
    end
  end
  has_many :links, dependent: :destroy
  has_many :identities, dependent: :destroy
  
  # Fields
  attr_accessible :title, :description, :contacts, :domain, :picture
  
  field :title, type: String
  field :description, type: String
  field :domain, type: String
  field :widgets, type: Hash
  
  # Validations
  validates :title, presence: true
  
  # Picture
  has_mongoid_attached_file :picture,
    styles: { preview: ["500x", :jpg] }
  
  # Representation
  def serializable_hash(options)
    super (options || {}).merge(
      except: [
        :_id, :widgets,
        :picture_content_type, :picture_file_name, :picture_file_size, :picture_updated_at
      ],
      methods: [:id, :preview_url]
    )
  end
  
  def has_charts?
    !self.nodes.charts.count.zero?
  end
  
  def charts
    self.nodes.charts
  end
  
  def has_identities?
    !self.identities.count.zero?
  end
  
  def widgets_enum
    %w(about charts people work_here contacts)
  end
  
  def to_param
    self.id
  end
  
  def preview_url
    self.picture.url(:preview)
  end
  
  def update_widgets(input)
    widgets = Hash[self.widgets_enum.map do |area|
      next unless input[area]
      
      widgets = input[area].uniq.compact
      # TODO: Validate
      [area, widgets]
    end]
    
    self.update_attribute(:widgets, widgets)
  end
  
  def initialize_widgets
    return {} unless self.widgets
    
    @rendered_widgets ||= Hash[self.widgets.map do |area, widgets|
      widgets.map! { |v| Widget.new(v).preload }
      [area, widgets]
    end]
  end
  
  def widget_areas
    return [] unless self.widgets
    
    self.widgets.select { |area, widgets| widgets.any? }.keys
  end
end
