class Identity
  include Mongoid::Document
  include Mongoid::Timestamps
  store_in collection: "identities"
  
  # Scopes
  scope :persons, -> { all.in(type: %w(person employee freelancer)) }
  scope :used, -> { all.ne(node_id: nil) }
  scope :unused, -> { all.where(node_id: nil) }
  
  # Relations
  belongs_to :organization
  belongs_to :node
  
  # Fields
  attr_accessible :organization_id, :node_id, :entity_id, :type, :position, :is_starred
  
  field :entity_id, type: Moped::BSON::ObjectId
  field :type, type: String, default: "vacancy"
  
  # field :title, type: String
  field :position, type: String
  field :is_starred, type: Boolean, default: false
  
  # TODO: Indexes
  
  # Fields
  def serializable_hash(options)
    super (options || {}).merge(
      except: [:_id],
      methods: [:id, :entity]
    )
  end
  
  def type_enum
    %w(person vacancy employee freelancer)
  end
  
  # Entities
  def to_person
    entity = self.entity
    if entity.is_a?(Person)
      entity.is_starred = self.is_starred
      entity.is_used = self.node_id.present?
      entity
    else
      nil
    end
  end
  
  def used?
    !!self.node_id
  end
  
  def person!(person, params = {})
    self.update_attributes(params.merge(type: "person", entity_id: person.id))
    self.save
  end
  
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
  def entity
    case self.type
    when "person", "employee", "freelancer"
      Person.find(self.entity_id) if self.entity_id
    end
  end
  
  def title
    case self.type
    when "person"
      self.entity.name
    when "vacancy"
      self.position
    when "employee"
      self.entity.name
    when "freelancer"
      self.type
    end
  end
end
