class User
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::Paperclip

  # Include default devise modules
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable,
         :invitable, :omniauthable

  # Relations
  # belongs_to :invitation
  # has_many :accesses, dependent: :destroy
  has_many :persons do
    def find_or_create_with_identifier(identifier)
      type, external_id = identifier.split(":")
      person = where(type: type, external_id: external_id).first_or_initialize
      person.fetch! if person.new_record?
      person
    end
  end

  ## Omniauthable
  embeds_many :authorizations do
    def find_by_uid(uid)
      self.where(uid: uid).first
    end
  end
  accepts_nested_attributes_for :authorizations

  ## Database authenticatable
  field :name,               type: String, default: ""
  field :email,              type: String, default: ""
  field :encrypted_password, type: String, default: ""

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

  ## Invitable
  include Mongoid::Token
  token length: 16, field_name: :invitation_token
  field :invitation_sent_at,      type: Time
  field :invitation_accepted_at,  type: Time
  field :invitation_limit,        type: Integer

  # Other
  field :is_god, type: Boolean

  # Validations
  validates_presence_of :email
  validates_presence_of :encrypted_password

  # Indexes
  ## Unique
  index({ email: 1 })
  ## Omniauth
  index({ "authorizations.provider" => 1, "authorizations.uid" => 1 })

  # Picture
  has_mongoid_attached_file :picture,
    styles: { preview: ["70x70#", :jpg] },
    default_url: "/images/ico-person.png"

  # Class methods
  def self.find_by_email(email)
    self.where(email: email).first
  end

  # Fields
  def serializable_hash(options)
    super (options || {}).merge(
      except: [:_id, :is_god, :email],
      methods: [:id]
    )
  end

  def god?
    Rails.env.development? ? true : self.is_god
  end
  
  # Clients
  def linkedin
    @linkedin ||= self.authorizations.where(provider: "Linkedin").first
  end
  
  def linkedin?
    !!self.linkedin
  end
  
  def linkedin_client
    @linkedin_client ||= LinkedIn::Client.new
    @linkedin_client.authorize_from_access(self.linkedin.token, self.linkedin.secret)
    @linkedin_client
  end
  
  def facebook
    @facebook ||= self.authorizations.where(provider: "Facebook").first
  end
  
  def facebook?
    !!self.facebook
  end
  
  def facebook_client
    @facebook_client ||= Koala::Facebook::API.new(self.facebook.token)
  end
  
  # Access
  # def access!(chart, level = :public!)
  #   self.accesses.where(chart_id: chart.id).first_or_initialize.send(level)
  # end
  # 
  # def charts
  #   self.accesses.ordered.map(&:chart)
  # end
end
