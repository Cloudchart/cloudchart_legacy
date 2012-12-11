class Node
  include Mongoid::Document
  include Mongoid::Tree
  include Mongoid::Tree::Traversal
  
  # Scopes
  scope :ordered, order_by(:id.asc)
  default_scope ordered
  scope :unordered, -> { all.tap { |criteria| criteria.options.store(:sort, nil) } }
  
  # Relations
  belongs_to :chart
  
  # Fields
  field :title, type: String
  
  # Validations
  validates :chart_id, presence: true
  validates :title, presence: true
  
  # Callbacks
  before_destroy :destroy_children
  
  # Indexes
  ## Ordered
  index({ chart_id: 1, _id: 1 })
  ## Tree
  index({ parent_id: 1, _id: 1 })
  
  def serializable_hash(options)
    super (options || {}).merge(except: [:_id], methods: [:id])
  end
end