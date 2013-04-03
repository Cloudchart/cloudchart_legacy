class Identity
  include Mongoid::Document
  store_in collection: "identities"
  
  # Relations
  belongs_to :node, validate: true
  belongs_to :person
  
  # Fields
  field :type, type: String, default: "employee"
  field :position, type: String
  
  def type_enum
    %w(employee freelancer vacancy)
  end
  
  def title
    case self.type
    when "employee"
      self.person.name
    when "freelancer", "vacancy"
      "#{self.type}: #{self.position}"
    end
  end
end
