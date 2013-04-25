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
  ## General
  field :type,        type: String
  field :external_id, type: String
  field :profile_url, type: String
  field :picture_url, type: String
  
  ## Personal
  field :first_name,  type: String, default: ""
  field :last_name,   type: String, default: ""
  field :birthday,    type: Date
  field :gender,      type: String
  field :hometown,    type: String
  field :location,    type: String
  
  ## Education, work, skills, bio
  field :education,   type: Array
  field :work,        type: Array
  field :skills,      type: Array
  field :description, type: String
  
  ## Contacts, networks
  field :phones,      type: Array
  
  ## Relationships
  field :status,      type: String
  field :family,      type: Array
  
  # Validations
  validates :type, presence: true
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
    indexes :name,         analyzer:  "standard", boost: 100
    indexes :employer,     analyzer:  "standard", boost: 50
    indexes :position,     analyzer:  "standard", boost: 50
  end
  def to_indexed_json
    { id: self.id, name: self.name, employer: self.employer, position: self.position }.to_json
  end
  
  # Fields
  def serializable_hash(options = {})
    super (options || {}).merge(
      except: [:_id, :picture_url],
      methods: [:id, :identifier, :name, :picture, :employer, :position, :headline, :persisted]
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
  
  def recent_work
    @recent_work ||= self.work.try(:first)
  end
  
  def position
    self.recent_work["position"] if self.recent_work
  end
  
  def employer
    self.recent_work["employer"]["name"] if self.recent_work
  end
  
  def headline
    "#{self.position} at #{self.employer}" if self.recent_work
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
