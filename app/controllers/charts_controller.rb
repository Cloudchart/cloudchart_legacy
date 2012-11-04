class ChartsController < ApplicationController
  before_filter :preload
  
  def demo
    @chart = Chart.demo.first
    
    respond_to { |format|
      format.xdot { render text: @chart.xdot }
    }
  end
  
  def index
    if user_signed_in?
      @charts = current_user.charts
    else
      @charts = []
    end
  end
  
  def show
    not_found unless @chart
    
    respond_to { |format|
      format.html { render }
      format.json { render json: @chart.as_json }
      format.xdot { render text: @chart.xdot }
      format.pdf  { render text: @chart.to_pdf }
    }
  end
  
  def create
    if user_signed_in?
      @chart = current_user.charts.create(title: I18n.t("charts.title"))
    else
      @chart = Chart.new
    end
    
    respond_to { |format|
      format.json {
        render json: { chart: @chart, redirect: chart_path(@chart.id) }
      }
    }
  end
  
  def edit
    not_found unless @chart || !user_signed_in? || @chart.user != current_user
  end
  
  def update
    not_found unless @chart || !user_signed_in? || @chart.user != current_user
    @chart.update_attributes params[:chart]
    redirect_to chart_path(@chart.id)
  end
  
  private
    
    def preload
      super
      @chart ||= Chart.find(params[:id]) if params[:id].present?
    end
end
