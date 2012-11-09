class VersionsController < ChartsController
  def index
    @versions = @chart.versions
  end
  
  def show
    @version = @chart.versions.where(version: params[:id]).first
    @version.id = @chart.id
    @chart = @version
    
    super
  end
  
  def edit
    @version = @chart.versions.where(version: params[:id]).first
    @version.id = @chart.id
    @chart = @version
    
    super
  end
  
  private
  
    def preload
      @chart ||= Chart.find_by_slug_or_id(params[:chart_id]) if params[:chart_id].present?
      
      super
    end
end