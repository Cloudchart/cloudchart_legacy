class Invitation
  include Mongoid::Document
  include ActionView::Helpers::TextHelper
  store_in collection: "invitations"
  
  # Relations
  belongs_to :template, class_name: "Invitation"
  has_many :invitables
  has_many :users
  
  # Fields
  field :from, type: String, default: ApplicationMailer.default[:from]
  field :subject, type: String, default: ""
  field :body, type: String, default: ""
  
  # Hidden fields
  field :body_hash, type: String, default: ""
  
  # Validations
  validates :template_id, presence: true, if: -> { self.body.blank? }
  validates :body, presence: true, if: -> { self.template.blank? }
  validates :from, presence: true
  validates :subject, presence: true
  
  # Callbacks
  before_save {
    # Pick up text from template
    self.body = self.template.body if self.template
    
    # Calculate body hash for uniqueness
    self.body_hash = Digest::MD5.hexdigest(self.body) if self.body_hash_changed?
  }
  
  after_save {
    # Convert invitables to invited users
    return true unless self.invitables.any?
    
    # Get routes instance
    @routes = Rails.application.routes.url_helpers
    
    self.invitables.each do |invitable|
      result = User.invite!({ email: invitable.email, skip_invitation: true })
      next unless result
      
      # Set invitation id
      result.set(:invitation_id, self.id)
      result.set(:name, invitable.name)
      
      # Send email
      status = ApplicationMailer.custom_invite(invitable.email, {
        from: self.from,
        subject: self.subject,
        body: self.body,
        
        name: invitable.name,
        link: @routes.accept_user_invitation_url(invitation_token: result.invitation_token)
      }).deliver
      
      # Remove invitable
      invitable.destroy if status
    end
  }
  
  def title
    truncate(self.body, length: 100)
  end
end
