class Widget
  include Mongoid::Document
  include Mongoid::Timestamps
  
  # Fields
  field :type, type: String
  field :values, type: Hash
  
  def self.type_enum
    %w(text header chart image person split)
  end
  
  def self.type_keys
    {
      text: [
        { name: :title, as: :string },
        { name: :contents, as: :text }
      ],
      header: [
        { name: :title, as: :string }
      ],
      chart: [
      ],
      image: [
        { name: :link, as: :string }
      ],
      person: [
      ],
      split: [
      ]
    }
  end
  
  def type_enum
    self.class.type_enum
  end
end
