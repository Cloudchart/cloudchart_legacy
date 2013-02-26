class Waiter
  include Mongoid::Document
  store_in collection: "waiters"
  
  # Fields
  field :email, type: String, default: ""
end
