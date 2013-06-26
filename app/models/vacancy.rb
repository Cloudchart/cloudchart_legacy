class Vacancy
  include Mongoid::Document
  include Mongoid::Timestamps
  store_in collection: "vacancies"
  
  # Scopes
  scope :ordered, order_by(:id.asc)
  default_scope ordered
  scope :unordered, -> { all.tap { |criteria| criteria.options.store(:sort, nil) } }
  
  # Relations
  belongs_to :organization
  
  # Fields
  attr_accessible :organization_id, :title
  field :title, type: String
  
  # Validations
  validates :title, presence: true
  
  # Tire
  include Tire::Model::Search
  include Tire::Model::Callbacks
  mapping do
    indexes :id,           index:     :not_analyzed
    indexes :title,        analyzer:  "standard", boost: 100
  end
  def to_indexed_json
    { id: self.id, title: self.title }.to_json
  end
  
  # Fields
  def serializable_hash(options = {})
    super (options || {}).merge(
      except: [:_id],
      methods: [
        :id, :identifier, :name
      ]
    )
  end
  
  # TODO: Adjust
  def name
    "Vacancy: #{self.title}"
  end
end
