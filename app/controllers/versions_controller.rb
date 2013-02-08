class VersionsController < ChartsController
  layout "chart", only: [:index, :show, :edit]
  
  def index
    respond_to { |format|
      format.html {
        render partial: "/versions/list", locals: { chart: @chart }
      }
    }
  end
  
  def show
    # Disable
    not_found
    
    @version = @chart.versions.where(version: params[:id]).first
    @version.id = @chart.id
    @version.slug = @chart.slug
    @chart = @version
    
    super
  end
  
  def edit
    # Disable
    not_found
    
    @version = @chart.versions.where(version: params[:id]).first
    @version.id = @chart.id
    @version.slug = @chart.slug
    @chart = @version
    
    super
  end
  
  def restore
    @chart.restore_from_version!(params[:version_id])
    
    respond_to { |format|
      format.json {
        render json: {
          redirect_to: edit_chart_path(@chart.slug_or_id)
        }
      }
    }
  end
  
  def clone
    @chart = @chart.create_from_version!(params[:version_id])
    
    respond_to { |format|
      format.json {
        render json: {
          redirect_to: edit_chart_path(@chart.slug_or_id)
        }
      }
    }
  end
  
  private
  
    def preload
      @chart ||= Chart.find_by_slug_or_id(params[:chart_id]) if params[:chart_id].present?
      not_found if !@chart && params[:chart_id].present?
      not_found unless can?(:edit, @chart)
      
      super
    end
end