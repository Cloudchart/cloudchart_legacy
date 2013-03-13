class Person
  include Mongoid::Document
  store_in collection: "persons"
  
  # Scopes
  scope :ordered, order_by(:id.asc)
  default_scope ordered
  scope :unordered, -> { all.tap { |criteria| criteria.options.store(:sort, nil) } }
  scope :linkedin, where(type: "ln")
  
  # Relations
  belongs_to :user
  
  # Fields
  attr_accessor :q
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
  
  def serializable_hash(options)
    super (options || {}).merge(except: [:_id, :picture_url], methods: [:id, :identifier, :name, :picture, :position, :company])
  end
  
  def identifier
    "#{self.name}(ln:#{self.external_id})"
  end
  
  def name
    "#{self.first_name} #{self.last_name}".strip
  end
  
  def picture
    @picture ||= (self.picture_url || "/images/ico-person.png")
  end
  
  def position
    self.headline.split(/\sat\s/).first if self.headline && self.headline.match(/\sat\s/)
  end
  
  def company
    self.headline.split(/\sat\s/).last if self.headline && self.headline.match(/\sat\s/)
  end
  
  def fetch!
    case self.type
    when "ln"
      attrs = self.user.linkedin_client.normalized_profile(self.external_id)
      attrs.delete(:id)
      self.update_attributes(attrs)
    end
    
    self
  end
end
