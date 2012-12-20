class LandingController < ApplicationController
  def index
    if user_signed_in?
      @charts = current_user.charts.ordered
    else
      @charts = charts_from_tokens
    end
    
    @charts = Chart.demo.all unless @charts.any?
  end
  
  def beta
    if params[:password].present?
      if params[:password] == "sayonara555"
        cookies[:beta] = { value: params[:password], expires: 365.days.from_now }
        redirect_to root_path
      else
        redirect_to url_for(wrong: 1)
      end
    end
    
    @meta = {
      description: I18n.t("app.beta")
    }
    
    render layout: false unless performed?
  end
end
