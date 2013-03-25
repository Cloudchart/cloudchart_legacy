class ApplicationController < ActionController::Base
  protect_from_forgery
  
  before_filter :preload
  before_filter :reload_rails_admin, if: :rails_admin_path?
  
  def not_found
    raise ActionController::RoutingError.new('Not Found')
  end
  
  rescue_from(
    ActionController::RoutingError,
    ActionController::UnknownController,
    ::AbstractController::ActionNotFound,
    Mongoid::Errors::DocumentNotFound, {
      with: lambda {
        raise if params[:controller] =~ /^rails_admin/
        render "/errors/404", layout: "application", locals: { cls: "application" }
      }
    })
  
  def current_ability
    @current_ability ||= Ability.new(current_user, charts_from_tokens)
  end
  
  private
    
    def charts_from_tokens
      return [] unless cookies["charts"].present?
      charts = ActiveSupport::JSON.decode(cookies["charts"]) || {} rescue {}
      charts.map { |_, v| Chart.where(id: v["id"], token: v["token"]).first }.compact
    end
    
    def preload
      # Check beta
      redirect_to beta_path and return if !beta_user_signed_in? && params[:action] != "beta" && !["invitations", "omniauth"].include?(params[:controller])
      
      # Check ie
      redirect_to ie_path if browser.ie? && !params[:action].in?(["ie", "beta"]) && !params[:controller].in?(["waiters"])
      
      # Convert charts access from cookie to database storage
      if user_signed_in? && charts_from_tokens.any?
        charts = ActiveSupport::JSON.decode(cookies["charts"]) || {} rescue {}
        charts_from_tokens.each do |chart|
          if !chart.owner || chart.owner.id == current_user.id
            charts.delete(chart.id.to_s)
          end
          
          # Give access
          if !chart.owner
            current_user.access!(chart, :owner!)
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
    
    # Rails Admin stuff
    def reload_rails_admin
      models = Mongoid::Document.models
      models.each { |m| RailsAdmin::Config.reset_model(m) }
      RailsAdmin::Config::Actions.reset
      load("#{Rails.root}/config/initializers/rails_admin.rb")
    end
    
    def rails_admin_path?
      controller_path =~ /rails_admin/ && Rails.env.development?
    end
    
end
