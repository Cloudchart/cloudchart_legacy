class ApplicationController < ActionController::Base
  protect_from_forgery
  before_filter :preload
  
  def current_ability
    @current_ability ||= Ability.new(current_user)
  end
  
  private
  
    def preload
    end
end
