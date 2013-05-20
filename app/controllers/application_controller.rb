class ApplicationController < ActionController::Base
  protect_from_forgery
  before_filter :preload
  
  def current_ability
    if params[:token]
      @token = Token.where(digest: params[:token]).first
      @current_ability ||= Ability.new(current_user, @token)
    else
      @current_ability ||= Ability.new(current_user)
    end
  end
  
  def after_sign_in_path_for(user)
    # Ensure user is set as owner to corresponding persons
    user.ensure_persons_ownership
    
    # Redirect
    session.delete(:redirect_to) || root_path
  end
  
  def after_oauth_path_for(user, provider)
    # Run import in background
    Importer.perform_async(user.id, provider)
    
    # Ensure user is set as owner to corresponding persons
    user.ensure_persons_ownership
    
    # Redirect
    session.delete(:redirect_to) || root_path
  end
  
  private
  
    def preload
      is_authenticating = %w(omniauth sessions registrations confirmations).include?(params[:controller])
      if !is_authenticating && (!flash[:notice] && !flash[:error]) && params[:format] != "json"
        session[:redirect_to] = request.fullpath
      end
    end
    
    def unauthorized
      respond_to do |format|
        format.html {
          redirect_to root_path, notice: I18n.t("devise.failure.unauthenticated")
        }
        
        format.json {
          render json: { errors: [I18n.t("devise.failure.unauthenticated")] }, status: :unauthorized
        }
      end
    end
end
