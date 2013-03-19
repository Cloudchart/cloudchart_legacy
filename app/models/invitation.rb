class Invitation
  include Mongoid::Document
  include ActionView::Helpers::TextHelper
  store_in collection: "invitations"
  
  # Relations
  belongs_to :template, class_name: "Invitation"
  
  # Fields
  field :from, type: String, default: "CloudChart Team <team@cloudorgchart.com>"
  field :email, type: String, default: ""
  field :name, type: String, default: ""
  field :subject, type: String, default: ""
  field :body, type: String, default: ""
  
  # Hidden fields
  field :body_hash, type: String, default: ""
  
  # Callbacks
  before_save {
    # Calculate body hash for uniqueness
    self.body_hash = Digest::MD5.hexdigest(self.body)
  }
  
  def title
    truncate(self.body, length: 100)
  end
end
