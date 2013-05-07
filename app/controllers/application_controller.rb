class ApplicationController < ActionController::Base
  protect_from_forgery
  before_filter :preload
  
  def current_ability
    @current_ability ||= Ability.new(current_user)
  end
  
  private
  
    def preload
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
