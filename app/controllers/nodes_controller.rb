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
    
    prepared_text = @chart.prepare_text_with_parent(@node, params[:chart][:text])
    current_text = @chart.prepare_text_with_parent(@node, params[:chart][:current_text])
    final_text = params[:chart][:previous_text].gsub(current_text, prepared_text)
    
    @chart.text = final_text
    @chart.save!
    
    redirect_to chart_path(@chart.slug_or_id)
  end
  
  private
  
    def preload
      @chart ||= Chart.find_by_slug_or_id(params[:chart_id]) if params[:chart_id].present?
      @node = @chart.nodes.find(params[:id]) if params[:id].present?
      
      super
    end
end