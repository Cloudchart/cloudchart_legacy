class Person
  include Mongoid::Document
  include Mongoid::Timestamps
  store_in collection: "persons"
  
  # Scopes
  scope :ordered, order_by(:id.asc)
  default_scope ordered
  scope :unordered, -> { all.tap { |criteria| criteria.options.store(:sort, nil) } }
  scope :permanent, where(is_permanent: true)
  
  scope :linkedin, where(type: "Linkedin")
  scope :facebook, where(type: "Facebook")
  
  # Relations
  belongs_to :user
  
  # Fields
  attr_accessor :organization, :is_starred, :is_used
  attr_accessible :type, :external_id, :profile_url, :picture_url,
                  :first_name, :last_name, :birthday, :gender, :hometown, :location,
                  :education, :work, :skills, :description,
                  :phones, :status, :family
  
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
  
  # Other fields
  field :is_permanent, type: Boolean, default: false
  
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
  
  # Callbacks
  before_save {
    # Check organization
    self.add_to_organization(self.organization) if self.organization
  }
  
  def gender_enum
    %w(male female)
  end
  
  # Token
  def token
    Token.where(type: self.class.to_s, entity_id: self.id, level: "update").first_or_create
  end
  
  def self.find_by_token(digest)
    token = Token.where(type: self.class.to_s, digest: digest).first
    self.class.find(token.entity_id) if token
  end
  
  # Class methods
  def self.identifier(params)
    "#{params["type"]}:#{params["external_id"]}"
  end
  
  def self.find_by_identifier(identifier)
    type, external_id = identifier.split(":")
    self.where(type: type, external_id: external_id).first
  end
  
  def self.find_or_create_with_identifier(identifier, current_user)
    type, external_id = identifier.split(":")
    person = self.where(type: type, external_id: external_id).first_or_initialize
    
    # Get data and set user_id
    if person.new_record?
      person.user_id = current_user.id
      person.fetch!
    end
    
    person
  end
  
  def self.find_or_create_with_params(params, current_user)
    person = self.where(type: params["type"], external_id: params["external_id"]).first_or_initialize
    
    # Set data and user_id
    if person.new_record?
      person.user_id = current_user.id
      person.update_attributes(params) if person.new_record?
    end
    
    person
  end
  
  # Fields
  def serializable_hash(options = {})
    super (options || {}).merge(
      except: [:_id, :picture_url],
      methods: [
        :id, :identifier, :name, :picture, :employer, :position, :headline,
        :is_persisted, :is_starred, :is_used
      ]
    )
  end
  
  # Representation
  def is_persisted
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
  
  # Organization
  def find_in_organization(organization)
    identity = Identity.persons.where(organization_id: organization.id, entity_id: self.id).first_or_initialize
    identity unless identity.new_record?
  end
  
  def add_to_organization(organization)
    self.permanent!
    identity = Identity.persons.where(organization_id: organization.id, entity_id: self.id).first_or_initialize
    identity.person!(self) if identity.new_record?
    identity
  end
  
  def use_in_organization(organization, node)
    self.permanent!
    identity = Identity.persons.where(organization_id: organization.id, entity_id: self.id).first_or_initialize
    identity.person!(self) if identity.new_record?
    identity.set(:node_id, node.id)
    identity
  end
  
  def permanent!
    self.set(:is_permanent, true)
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
