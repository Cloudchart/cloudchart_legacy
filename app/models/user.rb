class User
  include Mongoid::Document
  include Mongoid::Paperclip

  # Include default devise modules. Others available are:
  # :token_authenticatable, :confirmable,
  # :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable,
         :invitable, :omniauthable

  ## Database authenticatable
  field :name,               type: String, default: ""
  field :email,              type: String, default: ""
  field :encrypted_password, type: String, default: ""

  validates_presence_of :email
  validates_presence_of :encrypted_password
  
  ## Recoverable
  field :reset_password_token,   type: String
  field :reset_password_sent_at, type: Time

  ## Rememberable
  field :remember_created_at, type: Time

  ## Trackable
  field :sign_in_count,      type: Integer, default: 0
  field :current_sign_in_at, type: Time
  field :last_sign_in_at,    type: Time
  field :current_sign_in_ip, type: String
  field :last_sign_in_ip,    type: String

  ## Confirmable
  # field :confirmation_token,   :type => String
  # field :confirmed_at,         :type => Time
  # field :confirmation_sent_at, :type => Time
  # field :unconfirmed_email,    :type => String # Only if using reconfirmable

  ## Lockable
  # field :failed_attempts, :type => Integer, :default => 0 # Only if lock strategy is :failed_attempts
  # field :unlock_token,    :type => String # Only if unlock strategy is :email or :both
  # field :locked_at,       :type => Time

  ## Token authenticatable
  # field :authentication_token, :type => String

  ## Invitable
  include Mongoid::Token
  token length: 16, field_name: :invitation_token
  field :invitation_sent_at,      type: Time
  field :invitation_accepted_at,  type: Time
  field :invitation_limit,        type: Integer

  ## Omniauthable
  embeds_many :authorizations do
    def find_by_uid(uid)
      self.where(uid: uid).first
    end
  end
  accepts_nested_attributes_for :authorizations
  
  # Relations
  has_many :charts, dependent: :destroy
  has_many :persons, dependent: :destroy
  
  # Other
  field :is_god, type: Boolean
  
  # Indexes
  ## User unique identifiers
  index({ email: 1 })
  ## Omniauth query
  index({ "authorizations.provider" => 1, "authorizations.uid" => 1 })
  
  # Picture
  has_mongoid_attached_file :picture,
    styles: { preview: ["70x70#", :jpg] },
    default_url: "/images/ico-person.png"
  
  def serializable_hash(options)
    super (options || {}).merge(except: [:_id, :is_god, :email], methods: [:id, :charts])
  end
  
  def self.find_by_email(email)
    self.where(email: email).first
  end
  
  def self.find_by_username(username)
    self.where(username: username).first
  end
  
  def find_or_create_person(title)
    match = title.scan(/@([^\(]+)\(([^\:]+)\:([^\)]+)\)/).first
    person = self.persons.where(type: match[1], external_id: match[2]).first_or_create
    person.fetch! if person.new_record?
    person
  end
  
  def god?
    Rails.env.development? ? true : self.is_god
  end
  
  def linkedin
    @linkedin ||= self.authorizations.find_by(provider: "Linkedin")
  end
  
  def linkedin_client
    @linkedin_client ||= LinkedIn::Client.new
    @linkedin_client.authorize_from_access(self.linkedin.token, self.linkedin.secret)
    @linkedin_client
  end
end
