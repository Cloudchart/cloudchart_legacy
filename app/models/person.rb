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
  ## Slug
  index({ external_id: 1 })
  
  def serializable_hash(options)
    super (options || {}).merge(except: [:_id], methods: [:id])
  end
  
  def name
    "#{self.first_name} #{self.last_name}"
  end
  
  def fetch!
    case self.type
    when "ln"
      mapping = {
        first_name: :first_name,
        last_name: :last_name,
        picture_url: :picture_url,
        headline: :headline,
        summary: :description,
        :"site-standard-profile-request" => :profile_url
      }
      
      fetched = self.user.linkedin_client.profile(id: self.external_id, fields: mapping.keys)
      attrs = Hash[mapping.map { |k, v| [v, fetched[k]] }]
      attrs[:profile_url] = attrs[:profile_url].url if attrs[:profile_url]
      
      self.update_attributes attrs
    end
    
    self
  end
end
