class Authorization
  include Mongoid::Document
  store_in collection: "authorizations"

  # Relations
  belongs_to :user

  # Fields
  field :provider,  type: String
  field :uid,       type: String
  field :token,     type: String
  field :secret,    type: String
  field :name,      type: String
  field :link,      type: String

  # Validations
  validates :provider, presence: true
  validates :uid, presence: true

  def as_json(options = {})
    super except: [:_id], methods: [:id]
  end
end
