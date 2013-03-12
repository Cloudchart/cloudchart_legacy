class RegistrationsController < Devise::RegistrationsController
  def profile
    respond_to do |format|
      format.html { render partial: "/shared/profile" }
      format.json { render json: current_user }
    end
  end
  
  def edit
    @cls = "users"
    super
  end
  
  def update
    @cls = "users"
    super
  end
  
  def invite
    if params[:invite] && params[:invite][:email].present?
      emails = params[:invite][:email].split(",").map(&:strip).compact.uniq.delete_if { |x| x.blank? } rescue []
      emails.each do |email|
        result = User.invite!({ email: email, skip_invitation: true }, current_user)
        ApplicationMailer.invite(
          current_user,
          email,
          { link: accept_invitation_url(result, invitation_token: result.invitation_token) }
        ).deliver if result
      end
      
      # Reset for gods
      current_user.set(:invitation_limit, Devise.invitation_limit) if current_user.god?
    end
    
    redirect_to edit_user_registration_path
  end
end
