class Person
  include Mongoid::Document
  include Mongoid::Timestamps
  store_in collection: "persons"
  
  # Scopes
  scope :ordered, order_by(:id.asc)
  default_scope ordered
  scope :unordered, -> { all.tap { |criteria| criteria.options.store(:sort, nil) } }
  scope :linkedin, where(type: "Linkedin")
  scope :facebook, where(type: "Facebook")
  
  # Relations
  belongs_to :organization
  belongs_to :user
  
  # Fields
  field :type, type: String
  field :external_id, type: String
  field :first_name, type: String, default: ""
  field :last_name, type: String, default: ""
  field :picture_url, type: String
  field :headline, type: String
  field :description, type: String
  field :profile_url, type: String
  field :note, type: String
  
  # Validations
  validates :external_id, presence: true
  validates :first_name, presence: true
  validates :last_name, presence: true
  
  # Indexes
  ## Unique
  index({ user_id: 1, type: 1, external_id: 1 }, { unique: true })
  
  # Tire
  include Tire::Model::Search
  include Tire::Model::Callbacks
  mapping do
    indexes :id,           index:     :not_analyzed
    indexes :name,         analyzer:  'standard'
  end
  def to_indexed_json
    { id: self.id, name: self.name }.to_json
  end
  
  # Fields
  def serializable_hash(options = {})
    super (options || {}).merge(
      except: [:_id, :picture_url],
      methods: [:id, :identifier, :name, :picture, :position, :company, :persisted]
    )
  end
  
  # Representation
  def persisted
    self.persisted?
  end
  
  def identifier
    "#{self.type}:#{self.external_id}"
  end
  
  def name
    "#{self.first_name} #{self.last_name}".strip
  end
  
  def picture
    @picture ||= self.picture_url
  end
  
  def position
    self.headline.split(/\sat\s/).first if self.headline && self.headline.match(/\sat\s/)
  end
  
  def company
    self.headline.split(/\sat\s/).last if self.headline && self.headline.match(/\sat\s/)
  end
  
  # External
  def fetch!
    case self.type
    when "Linkedin"
      attrs = self.user.linkedin_client.normalized_profile(self.external_id)
      self.update_attributes(attrs)
    when "Facebook"
      attrs = self.user.facebook_client.normalized_profile(self.external_id)
      self.update_attributes(attrs)
    end
    
    self
  end
end
