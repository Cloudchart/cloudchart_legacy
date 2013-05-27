class RegistrationsController < Devise::RegistrationsController
  def update
    @user = User.find(current_user.id)
    
    # required for settings form to submit when password is left blank
    if params[:user][:password].blank?
      params[:user].delete("password")
      params[:user].delete("password_confirmation")
    end
    
    # Update connected emails
    if emails = params[:user].delete("emails")
      update_emails(emails)
    end
    
    if @user.update_attributes(params[:user])
      set_flash_message :notice, :updated
      # Sign in the user bypassing validation in case his password changed
      sign_in @user, :bypass => true
      redirect_to after_update_path_for(@user)
    else
      render "edit"
    end
  end
  
  private
  
    def update_emails(emails)
      emails = emails.select { |k, v| v =~ Devise.email_regexp }.values
      confirmations = []
      emails.each do |email|
        authorization = current_user.authorizations.email.where(uid: email).first_or_initialize
        if authorization.new_record?
          current_user.authorizations << authorization
          confirmations << authorization
        end
      end
      
      if confirmations.any?
        current_user.save
        # TODO: Send confirmation emails
      end
    end
    
    def after_update_path_for(user)
      edit_user_registration_path
    end
end
