class Widget
  include Mongoid::Document
  include Mongoid::Timestamps
  
  # Fields
  attr_accessor :chart, :person
  
  field :type, type: String
  field :values, type: Hash
  
  def self.type_enum
    %w(text picture chart person widget split)
  end
  
  def self.type_config
    {
      text: {
        icon: "font",
        keys: [
          { name: :contents, as: :text }
        ]
      },
      picture: {
        icon: "picture",
        keys: [
          { name: :url, as: :string }
        ]
      },
      chart: {
        icon: "table",
        keys: [
          { name: :id }
        ]
      },
      person: {
        icon: "user",
        keys: [
          { name: :id }
        ]
      },
      widget: {
        icon: "bar-chart",
        keys: [
        ]
      },
      split: {
        icon: "ellipsis-horizontal",
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
