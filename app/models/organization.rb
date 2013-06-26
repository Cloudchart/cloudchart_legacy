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
  has_many :vacancies, dependent: :destroy
  
  # Fields
  attr_accessible :title, :contacts, :domain, :picture
  
  field :title, type: String
  field :domain, type: String
  field :widgets, type: Hash
  
  # Validations
  validates :title, presence: true
  
  # Picture
  has_mongoid_attached_file :picture,
    styles: { preview: ["500x", :png] }
  
  # Uploads
  has_many :uploads, class_name: "Picture"
  
  # Callbacks
  before_create {
    # Default widgets
    self.widgets = {
      about: [{ "type" => "text", "values" => {} }],
      charts: [{ "type" => "charts", "values" => {} }]
    } unless self.widgets
  }
  
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
  
  def to_param
    self.id
  end
  
  def preview_url
    self.picture.url(:preview)
  end
  
  def has_charts?
    !self.nodes.charts.count.zero?
  end
  
  def charts
    self.nodes.charts.cache
  end
  
  def has_identities?
    !self.identities.count.zero?
  end
  
  def description
    return nil unless self.widget_areas.include?("about")
    text = self.widgets["about"].find { |widget| widget["type"] == "text" }
    text["values"]["contents"] if text
  end
  
  def widgets_enum
    %w(about charts people work_here contacts)
  end
  
  def has_widgets?
    self.widget_areas.any?
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
      rendered = widgets.map { |v| Widget.new(v).preload }
      [area, rendered]
    end]
  end
  
  def widget_areas
    return [] unless self.widgets
    
    self.widgets.select { |area, widgets|
      if area == "charts" && self.has_charts?
        true
      else
        widgets.select { |widget|
          (widget["values"] || {}).select { |k, v| v.present? }.any?
        }.any?
      end
    }.keys
  end
end
