class Waiter
  include Mongoid::Document
  
  # Fields
  field :email, type: String, default: ""
end
