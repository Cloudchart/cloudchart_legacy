class ApplicationController < ActionController::Base
  protect_from_forgery
  before_filter :preload
  
  def not_found
    raise ActionController::RoutingError.new('Not Found')
  end
  
  rescue_from(
    ActionController::RoutingError,
    ActionController::UnknownController,
    ::AbstractController::ActionNotFound,
    Mongoid::Errors::DocumentNotFound, {
      with: lambda {
        render "/errors/404", layout: "application", locals: { cls: "application" }
      }
    })
  
  def current_ability
    @current_ability ||= Ability.new(current_user, charts_from_tokens)
  end
  
  private
  
    def charts_from_tokens
      return [] unless cookies["charts"].present?
      charts = ActiveSupport::JSON.decode(cookies["charts"]) rescue {}
      charts.map { |_, v| Chart.where(id: v["id"], token: v["token"]).first }.compact
    end
    
    def preload
      # Check beta
      redirect_to beta_path and return if !beta_user_signed_in? && params[:action] != "beta" && !["invitations", "omniauth"].include?(params[:controller])
      
      # Check ie
      # redirect_to ie_path unless params[:action].in? ["ie", "beta"]
      
      if user_signed_in? && charts_from_tokens.any?
        charts = ActiveSupport::JSON.decode(cookies["charts"]) rescue {}
        charts_from_tokens.each do |chart|
          if !chart.user_id || chart.user_id == current_user.id
            charts.delete(chart.id.to_s)
          end
          if !chart.user_id
            chart.set(:user_id, current_user.id)
          end
        end
        
        if charts.any?
          cookies["charts"] = { value: charts.to_json, expires: 1.year.from_now, path: "/" }
        else
          cookies.delete("charts")
        end
      end
    end
    
    def beta_token
      "sayonara555"
    end
    
    def sign_in_beta_user
      cookies[:beta] = { value: beta_token, expires: 365.days.from_now }
    end
    
    def beta_user_signed_in?
      cookies[:beta] == beta_token
    end
    
end
