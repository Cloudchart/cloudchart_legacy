class Identity
  include Mongoid::Document
  store_in collection: "identities"
  
  # Relations
  belongs_to :node
  belongs_to :person
  
  # Fields
  field :type, type: String, default: "employee"
  field :position, type: String
  
  # Validations
  validates :node_id, presence: true
  
  def title
    case self.type
    when "employee"
      self.person.name
    when "vacancy"
      "#{self.type}: #{self.position}"
    end
  end
end
