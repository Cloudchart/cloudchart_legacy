class Organization
  include Mongoid::Document
  include Mongoid::Token
  store_in collection: "organizations"
  
  # Relations
  has_many :nodes do
    def create_chart_node(params)
      charts.where(params).create
    end
  end
  has_many :links
  
  # Fields
  attr_accessible :title
  field :title, type: String
  
  # Validations
  validates :title, presence: true
  
  # Token
  token length: 16
end
