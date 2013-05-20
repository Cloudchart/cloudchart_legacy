class Token
  include Mongoid::Document
  include Mongoid::Timestamps
  store_in collection: "tokens"
  
  # Fields
  field :entity_id, type: Moped::BSON::ObjectId
  field :type, type: String
  field :level, type: String
  field :digest, type: String
  
  # Validations
  validates :entity_id, presence: true
  validates :type, presence: true
  validates :level, presence: true
  validates :digest, presence: true
  
  # Callbacks
  after_initialize {
    self.digest ||= Digest::MD5.hexdigest(Time.new.to_s + rand.to_s)[0..23].to_s
  }
  
  def level_enum
    %w(show update)
  end
  
  def entity
    self.type.constantize.find(self.entity_id)
  end
end
