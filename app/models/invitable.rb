class Invitable
  include Mongoid::Document
  store_in collection: "invitables"
  
  # Relations
  belongs_to :invitation
  
  # Fields
  field :name
  field :email
  
  # Validations
  validates :email, presence: true
  
  def title
    (self.name.present? && self.name) || self.email
  end
end
