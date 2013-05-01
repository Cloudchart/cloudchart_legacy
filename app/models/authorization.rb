class Authorization
  include Mongoid::Document

  # Relations
  embedded_in :user

  # Fields
  attr_accessible :provider, :uid, :token, :secret, :name, :link

  field :provider,  type: String
  field :uid,       type: String
  field :token,     type: String
  field :secret,    type: String
  field :name,      type: String
  field :link,      type: String

  # Validations
  validates :provider, presence: true
  validates :uid, presence: true

  # Fiels
  def serializable_hash(options)
    super (options || {}).merge(except: [:_id], methods: [:id])
  end
end
