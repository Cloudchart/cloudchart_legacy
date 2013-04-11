class ApplicationController < ActionController::Base
  protect_from_forgery
  before_filter :preload
  
  # FIXME: Debug
  def home
    render json: current_user
  end
  
  private
  
    def preload
    end
end
