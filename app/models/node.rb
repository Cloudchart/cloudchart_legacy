class Node
  include Mongoid::Document
  include Mongoid::Tree
  include Mongoid::Tree::Traversal
  
  # Relations
  belongs_to :chart
  
  # Fields
  field :title, type: String
  
  # Validations
  validates :chart_id, presence: true
  validates :title, presence: true
  
  # Callbacks
  before_destroy :destroy_children
  
  def as_json(options = {})
    super except: [:_id], methods: [:id]
  end
end