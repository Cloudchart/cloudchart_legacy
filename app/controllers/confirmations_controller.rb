class ConfirmationsController < Devise::ConfirmationsController
  def show
    if user_signed_in?
      authorization = current_user.authorizations.email.where(token: params[:confirmation_token]).first_or_initialize
      
      # Confirm it!
      if authorization.persisted?
        authorization.set(:is_confirmed, true)
        redirect_to edit_user_registration_path
      else
        super
      end
    else
      super
    end
  end
end
