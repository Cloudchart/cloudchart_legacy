class ApplicationController < ActionController::Base
  protect_from_forgery
  before_filter :preload
  
  def not_found
    raise ActionController::RoutingError.new('Not Found')
  end
  
  def current_ability
    @current_ability ||= Ability.new(current_user, charts_from_tokens)
  end
  
  private
  
    def charts_from_tokens
      return [] unless cookies["charts"].present?
      charts = ActiveSupport::JSON.decode(cookies["charts"]) rescue []
      charts.map { |_, v| Chart.where(id: v["id"], token: v["token"]).first }.compact
    end
    
    def preload
      if user_signed_in? && charts_from_tokens.any?
        charts_from_tokens.each do |chart|
          chart.set(:user_id, current_user.id) unless chart.user_id
        end
        cookies.delete("charts")
      end
    end
end
