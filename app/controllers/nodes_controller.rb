class NodesController < ChartsController
  def show
    # Replace xdot
    @chart.xdot = @chart.to_xdot_with_parent(@node)
    
    super
  end
  
  def edit
    # Replace xdot
    @chart.xdot = @chart.to_xdot_with_parent(@node)
    
    # Replace text
    @chart.previous_text = @chart.text
    @chart.text = @chart.to_text_with_parent(@node)
  end
  
  def update
    # Update only text
    not_found unless can?(:update, @chart)
    
    prepared_text = @chart.prepare_text_with_parent(@node, params[:chart][:text])
    current_text = @chart.prepare_text_with_parent(@node, params[:chart][:current_text])
    
    if current_text.present?
      final_text = params[:chart][:previous_text].gsub(current_text, prepared_text)
    else
      final_text = params[:chart][:previous_text].gsub("#{@node.title}\r\n", "#{@node.title}\r\n#{prepared_text}\r\n")
    end
    
    @chart.text = final_text
    @chart.save!
    
    # Replace xdot
    @node = @chart.nodes.find_by(title: @node.title)
    @chart.xdot = @chart.to_xdot_with_parent(@node)
    
    respond_to { |format|
      format.html {
        redirect_to edit_chart_path(@chart.slug_or_id)
      }
      format.json {
        render json: {
          chart: @chart,
          action_to: chart_node_path(chart_id: @chart.slug_or_id, id: @node.id),
          redirect_to: edit_chart_node_path(chart_id: @chart.slug_or_id, id: @node.id)
        }
      }
    }
  end
  
  private
  
    def preload
      @chart ||= Chart.find_by_slug_or_id(params[:chart_id]) if params[:chart_id].present?
      @node = @chart.nodes.find(params[:id]) if params[:id].present?
      
      super
    end
end