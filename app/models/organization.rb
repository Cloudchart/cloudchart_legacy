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
  field :contacts, type: String
  
  # Validations
  validates :title, presence: true
  
  # Picture
  has_mongoid_attached_file :picture,
    styles: { preview: ["500x", :jpg] }
  
  # Representation
  def has_charts?
    !self.nodes.charts.count.zero?
  end
  
  def charts
    self.nodes.charts
  end
  
  def has_identities?
    !self.identities.count.zero?
  end
  
  def to_param
    self.id
  end
end
