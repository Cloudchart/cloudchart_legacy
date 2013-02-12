class NodesController < ChartsController
  def show
    # Replace xdot
    @chart.xdot = @chart.to_xdot_with_parent(@node)
    @persons = @chart.persons_with_parent(@node)
    
    respond_to { |format|
      format.html { render }
      format.xdot { render text: @chart.xdot }
      format.pdf  { render text: @chart.to_pdf(@node) }
    }
  end
  
  def edit
    not_found unless can?(:update, @chart)
    
    # Replace xdot
    @chart.xdot = @chart.to_xdot_with_parent(@node)
    @persons = @chart.persons_with_parent(@node)
    
    # Replace text
    @chart.previous_text = @chart.text
    @chart.text = @chart.to_text_with_parent(@node)
  end
  
  def update
    not_found unless can?(:update, @chart)
    
    # Update only text
    prepared_text = @chart.prepare_text_with_parent(@node, params[:chart][:text])
    current_text = @chart.prepare_text_with_parent(@node, params[:chart][:current_text])
    
    if current_text.present?
      final_text = params[:chart][:previous_text]
      prepared_text = prepared_text.split("\r\n")
      current_text = current_text.split("\r\n")
      
      current_text.each_with_index do |line, idx|
        final_text.gsub!(line, prepared_text[idx] || "")
      end
      
      if current_text.length < prepared_text.length && prepared_text[current_text.length..-1].any?
        final_text.gsub!(prepared_text[current_text.length-1], prepared_text[current_text.length-1..-1].join("\r\n"))
      end
    else
      final_text = params[:chart][:previous_text].gsub("#{@node.title}\r\n", "#{@node.title}\r\n#{prepared_text.rstrip}\r\n")
    end
    
    @chart.title = params[:chart][:title]
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
          breadcrumb: render_to_string(partial: "/nodes/breadcrumb", formats: [:html], locals: { insert: true }),
          pdf_to: chart_node_path(chart_id: @chart.slug_or_id, id: @node.id, format: :pdf),
          action_to: chart_node_path(chart_id: @chart.slug_or_id, id: @node.id),
          redirect_to: edit_chart_node_path(chart_id: @chart.slug_or_id, id: @node.id)
        }
      }
    }
  end
  
  private
  
    def preload
      @chart ||= Chart.find_by_slug_or_id(params[:chart_id]) if params[:chart_id].present?
      not_found if !@chart && params[:chart_id].present?
      @node = @chart.nodes.find(params[:id]) if params[:id].present?
      
      super
    end
end