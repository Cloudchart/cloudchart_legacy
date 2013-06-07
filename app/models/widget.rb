class Widget
  include Mongoid::Document
  include Mongoid::Timestamps
  
  # Fields
  attr_accessor :chart, :person
  
  field :type, type: String
  field :values, type: Hash
  
  def self.type_enum
    %w(text header chart image person split)
  end
  
  def self.type_config
    {
      text: {
        keys: [
          { name: :title, as: :string },
          { name: :contents, as: :text }
        ]
      },
      header: {
        keys: [
          { name: :title, as: :string }
        ]
      },
      chart: {
        keys: [
          { name: :id, as: :select, collection: "charts" }
        ]
      },
      image: {
        keys: [
          { name: :link, as: :string }
        ]
      },
      person: {
        keys: [
          { name: :id, as: :select, collection: "persons" }
        ]
      },
      split: {
        unique: true,
        keys: [
        ]
      }
    }
  end
  
  def type_enum
    self.class.type_enum
  end
  
  def split?
    self.type == "split"
  end
  
  def preload
    case self.type
    when "chart"
      self.chart = Node.find(self.values["id"]) if self.values["id"].present?
    end
    
    self
  end
end
