class Vacancy
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::MultiParameterAttributes
  store_in collection: "vacancies"
  
  # Scopes
  scope :ordered, order_by(:id.asc)
  default_scope ordered
  scope :unordered, -> { all.tap { |criteria| criteria.options.store(:sort, nil) } }
  scope :enabled, -> { where(is_enabled: true) }
  
  # Relations
  belongs_to :organization
  has_and_belongs_to_many :responders, class_name: "User", inverse_of: nil
  
  # Fields
  attr_accessible :organization_id, :title, :description, :requirements,
                  :salary, :starts_at, :location, :contact, :is_enabled
  
  field :title, type: String
  field :description, type: String
  field :requirements, type: String
  field :salary, type: Integer
  field :starts_at, type: Date
  field :location, type: String
  field :contact, type: String
  field :is_enabled, type: Boolean, default: true
  
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
  
  def enabled?
    !!self.is_enabled
  end
  
  def respond!(user)
    self.responders.push(user) unless self.responded?(user)
  end
  
  def responded?(user)
    self.responder_ids.include?(user.id)
  end
  
  # TODO: Adjust
  def name
    "Vacancy: #{self.title}"
  end
end
