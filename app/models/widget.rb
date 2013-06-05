class Widget
  include Mongoid::Document
  include Mongoid::Timestamps
  
  def self.type_enum
    %w(text header chart image person split)
  end
end
