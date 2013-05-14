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
  
  private
  
    def preload
      current_ability
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
