class Organization
  include Mongoid::Document
  include Mongoid::Timestamps
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
  attr_accessible :title
  
  field :title, type: String
  
  # Validations
  validates :title, presence: true
  
  # Representation
  def to_param
    self.id
  end
end
