class VersionsController < ChartsController
  layout "chart", only: [:index, :show, :edit]
  
  def index
    # Disable
    not_found
    
    @versions = @chart.versions
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
  
  private
  
    def preload
      @chart ||= Chart.find_by_slug_or_id(params[:chart_id]) if params[:chart_id].present?
      
      super
    end
end