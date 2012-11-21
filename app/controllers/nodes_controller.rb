class NodesController < ChartsController
  def show
    # Replace xdot
    @chart.xdot = @chart.to_xdot_with_parent(@node)
    
    super
  end
  
  def edit
    # Replace text
    @chart.previous_text = @chart.text
    @chart.text = @chart.to_text_with_parent(@node)
  end
  
  def update
    # Update only text
    not_found unless can?(:update, @chart)
    @chart.text = params[:chart][:previous_text].gsub(params[:chart][:current_text], @chart.prepare_text_with_parent(@node, params[:chart][:text]))
    @chart.save!
    redirect_to chart_path(@chart.slug_or_id)
  end
  
  private
  
    def preload
      @chart ||= Chart.find_by_slug_or_id(params[:chart_id]) if params[:chart_id].present?
      @node = @chart.nodes.find(params[:id])
      
      super
    end
end