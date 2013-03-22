class ChartsController < ApplicationController
  layout "chart", only: [:show, :token]
  
  def index
    if user_signed_in?
      @charts = current_user.charts.ordered
    else
      @charts = charts_from_tokens
    end
  end
  
  def show
    not_found unless @chart
    
    # Check access
    # Public
    current_user.access!(@chart, :public!) if user_signed_in?
    
    @meta = {
      title: @chart.title,
      description: @chart.user_id ? I18n.t("charts.author", author: @chart.user.name) : nil,
      image: @chart.to_png(:preview)
    }
    
    # @chart.to_xdot! if Rails.env.development?
    
    respond_to { |format|
      format.html { render :edit }
      format.json { render json: @chart.as_json }
      format.xdot { render text: @chart.to_xdot }
      format.pdf  { render text: @chart.to_pdf }
      format.png  { redirect_to @chart.to_png }
    }
  end
  
  def token
    not_found unless @chart.token == params[:token]
    
    # Check access
    # Token
    current_user.access!(@chart, :token!) if user_signed_in?
    
    if !user_signed_in? || @chart.user_id != current_user.id
      charts = ActiveSupport::JSON.decode(cookies["charts"]) || {} rescue {}
      charts[@chart.id.to_s] = { id: @chart.id.to_s, token: @chart.token }
      cookies["charts"] = { value: charts.to_json, expires: 1.year.from_now, path: "/" }
    end
    
    render :edit
  end
  
  def create
    if user_signed_in?
      @chart = current_user.charts.create(title: I18n.t("charts.title"))
    else
      @chart = Chart.create(title: I18n.t("charts.title"))
    end
    
    respond_to { |format|
      format.html {
        redirect_to chart_path(@chart.slug_or_id)
      }
      format.json {
        render json: { chart: @chart.as_json.merge(token: @chart.token), redirect_to: chart_path(@chart.slug_or_id) }
      }
    }
  end
  
  def clone
    not_found unless @chart.demo?
    @cloned_chart = @chart
    
    if user_signed_in?
      @chart = current_user.charts.create(title: @cloned_chart.title)
    else
      @chart = Chart.create(title: @cloned_chart.title)
    end
    
    @chart.text = @cloned_chart.text
    @chart.save!
    
    respond_to { |format|
      format.html {
        redirect_to chart_path(@chart.slug_or_id)
      }
      format.json {
        render json: { chart: @chart.as_json.merge(token: @chart.token), redirect_to: chart_path(@chart.slug_or_id) }
      }
    }
  end
  
  def update
    not_found unless can?(:update, @chart)
    @chart.update_attributes params[:chart]
    # @chart.to_png
    
    respond_to { |format|
      format.html {
        redirect_to chart_path(@chart.slug_or_id)
      }
      format.json {
        render json: {
          chart: @chart,
          action_to: chart_path(@chart.id),
          redirect_to: chart_path(@chart.slug_or_id)
        }
      }
    }
  end
  
  def share
    not_found unless can?(:update, @chart)
    
    begin
      email = params[:share][:"#{params[:share][:type]}_email"]
      raise StandardError unless email =~ Devise.email_regexp
      
      ApplicationMailer.share(
        user_signed_in? ? current_user : nil,
        @chart,
        email,
        { link: params[:share][:"#{params[:share][:type]}"] }
      ).deliver
      
      respond_to { |format|
        format.json {
          render json: {}
        }
      }
    rescue
      respond_to { |format|
        format.json {
          render json: {}, status: :unprocessable_entity
        }
      }
    end
  end
  
  def destroy
    not_found unless can?(:destroy, @chart)
    @chart.destroy
    
    respond_to { |format|
      format.json {
        render json: {
          redirect_to: charts_path
        }
      }
    }
  end
  
  private
    
    def preload
      super
      
      @chart ||= Chart.find_by_slug_or_id(params[:id]) if params[:id].present?
      not_found if !@chart && params[:id].present?
    end
end
