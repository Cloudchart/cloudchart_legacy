class InvitationsController < Devise::InvitationsController
  def edit
    if params[:invitation_token] && self.resource = resource_class.accept_invitation!(invitation_token: params[:invitation_token], password: SecureRandom.hex)
      sign_in_beta_user
      redirect_to root_path
    else
      super
    end
  end
end
