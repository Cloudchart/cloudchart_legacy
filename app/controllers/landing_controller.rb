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
      if params[:password] == beta_token
        sign_in_beta_user
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
