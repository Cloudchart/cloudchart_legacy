class LandingController < ApplicationController
  def index
    if user_signed_in?
      @charts = current_user.charts.ordered
    else
      @charts = charts_from_tokens
    end
    
    @charts = Chart.demo.all unless @charts.any?
  end
end
