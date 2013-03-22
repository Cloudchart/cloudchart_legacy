class Access
  include Mongoid::Document
  include Mongoid::Timestamps
  store_in collection: "accesses"
  
  # Scopes
  scope :ordered, order_by(:updated_at.desc)
  scope :unordered, -> { all.tap { |criteria| criteria.options.store(:sort, nil) } }
  
  # Relations
  belongs_to :user
  belongs_to :chart
  
  # Fields
  field :level, type: String, default: "public"
  
  # Indexes
  ## Unique
  index({ user_id: 1, chart_id: 1 }, { unique: true })
  
  def level_enum
    ["public", "token", "owner"]
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
