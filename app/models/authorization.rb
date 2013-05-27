class Authorization
  include Mongoid::Document
  
  # Relations
  embedded_in :user
  
  # Scopes
  scope :linkedin, -> { where(provider: "Linkedin") }
  scope :facebook, -> { where(provider: "Facebook") }
  scope :email, -> { where(provider: "Email") }
  
  # Fields
  attr_accessible :provider, :uid, :token, :secret, :name, :link
  
  field :provider,      type: String
  field :uid,           type: String
  field :token,         type: String
  field :secret,        type: String
  field :name,          type: String
  field :link,          type: String
  field :is_confirmed,  type: Boolean
  
  # Validations
  validates :provider, presence: true
  validates :uid, presence: true
  
  # Callbacks
  before_save {
    if self.provider == "Email"
      self.token ||= Digest::MD5.hexdigest(Time.new.to_s + rand.to_s)[0..23].to_s
    end
  }
  
  # Fields
  def serializable_hash(options)
    super (options || {}).merge(except: [:_id], methods: [:id])
  end
  
  def provider_enum
    %w(Linkedin Facebook Email)
  end
  
  def confirmed?
    !!self.is_confirmed
  end
end
