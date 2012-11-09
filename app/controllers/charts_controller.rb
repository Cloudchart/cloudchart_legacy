class ChartsController < ApplicationController
  def index
    if user_signed_in?
      @charts = current_user.charts
    else
      @charts = charts_from_tokens
    end
  end
  
  def show
    not_found unless @chart
    
    @meta = {
      title: @chart.title,
      description: I18n.t("charts.author", author: @chart.user.name),
      image: @chart.to_png(:preview)
    }
    
    respond_to { |format|
      format.html { render }
      format.json { render json: @chart.as_json }
      format.xdot { render text: @chart.to_xdot }
      format.pdf  { render text: @chart.to_pdf }
      format.png  { redirect_to @chart.to_png }
    }
  end
  
  def token
    not_found unless @chart.token == params[:token]
    if !user_signed_in? || @chart.user_id != current_user.id
      charts = ActiveSupport::JSON.decode(cookies["charts"]) rescue {}
      charts[@chart.id.to_s] = { id: @chart.id.to_s, token: @chart.token }
      cookies["charts"] = { value: charts.to_json, expires: 1.year.from_now, path: "/" }
    end
    
    render :show
  end
  
  def create
    if user_signed_in?
      @chart = current_user.charts.create(title: I18n.t("charts.title"))
    else
      @chart = Chart.create(title: I18n.t("charts.title"))
    end
    
    respond_to { |format|
      format.json {
        render json: { chart: @chart.as_json.merge(token: @chart.token), redirect: chart_path(@chart.slug_or_id) }
      }
    }
  end
  
  def edit
    not_found unless can?(:edit, @chart)
  end
  
  def update
    not_found unless can?(:update, @chart)
    @chart.update_attributes params[:chart]
    redirect_to chart_path(@chart.slug_or_id)
  end
  
  private
    
    def preload
      super
      
      @chart ||= Chart.find_by_slug_or_id(params[:id]) if params[:id].present?
    end
end
