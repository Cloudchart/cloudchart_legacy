class Access
  include Mongoid::Document
  include Mongoid::Timestamps
  store_in collection: "accesses"
  
  # Scopes
  scope :ordered, order_by(:updated_at.desc)
  scope :unordered, -> { all.tap { |criteria| criteria.options.store(:sort, nil) } }
  
  scope :organizations, -> { where(type: "organization") }
  scope :nodes, -> { where(type: "node") }
  
  scope :publics, -> { where(level: "public") }
  scope :tokens, -> { where(level: "token") }
  scope :owners, -> { where(level: "owner") }
  scope :editables, -> { all.in(level: ["token", "owner"]) }
  
  # Relations
  belongs_to :user
  
  # Fields
  field :entity_id, type: Moped::BSON::ObjectId
  field :type, type: String
  field :level, type: String, default: "public"
  
  def type_enum
    %w(organization node)
  end
  
  def level_enum
    %w(public token owner)
  end
  
  def public!
    return self if self.editable?
    
    self.level = "public"
    self.save
  end
  
  def public?
    self.level == "public"
  end
  
  def token!
    return self if self.owner?
    
    self.level = "token"
    self.save
  end
  
  def token?
    self.level == "token"
  end
  
  def owner!
    self.level = "owner"
    self.save
  end
  
  def owner?
    self.level == "owner"
  end
  
  def editable?
    self.token? || self.owner?
  end
end
