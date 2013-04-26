class Organization
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::Token
  store_in collection: "organizations"
  
  # Relations
  has_many :nodes, dependent: :destroy do
    def create_chart_node(params)
      charts.where(params).create
    end
  end
  has_many :links, dependent: :destroy
  
  # Persons
  has_and_belongs_to_many :added_persons, class_name: "Person", inverse_of: "added_organizations"
  has_and_belongs_to_many :used_persons, class_name: "Person", inverse_of: "used_organizations"
  
  def persons
    Person.in(id: self.added_person_ids + self.used_person_ids)
  end
  
  # Fields
  attr_accessible :title
  field :title, type: String
  
  # Validations
  validates :title, presence: true
  
  # Token
  token length: 16
  
  # Representation
  def to_param
    self.id
  end
end
