class Identity
  include Mongoid::Document
  store_in collection: "identities"
  
  # Relations
  belongs_to :node, validate: true
  
  # Fields
  field :type, type: String, default: "vacancy"
  field :entity_id, type: Moped::BSON::ObjectId
  
  # field :title, type: String
  field :position, type: String
  
  # TODO: Indexes
  
  # Fields
  def serializable_hash(options)
    super (options || {}).merge(
      except: [:_id],
      methods: [:id]
    )
  end
  
  def type_enum
    %w(vacancy employee freelancer)
  end
  
  # Entities
  def vacancy!(params = {})
    self.update_attributes(params.merge(type: "vacancy"))
    self
  end
  
  def employee!(person, params = {})
    self.update_attributes(params.merge(type: "employee", entity_id: person.id))
    self.save
  end
  
  def freelancer!(person, params = {})
    self.update_attributes(params.merge(type: "freelancer", entity_id: person.id))
    self.save
  end
  
  # Representation
  def title
    case self.type
    when "vacancy"
      self.position
    when "employee"
      Person.find(self.entity_id).name
    when "freelancer"
      self.type
    end
  end
end
