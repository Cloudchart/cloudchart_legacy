class NodesController < ApplicationController
  def index
    @nodes = Node.charts
    
    respond_to do |format|
      format.json { render json: @nodes }
    end
  end
  
  def show
    respond_to do |format|
      format.json {
        render json: { 
          root_id: @node.id,
          ancestor_ids: @node.ancestor_ids,
          nodes: @node.descendant_and_ancestor_nodes,
          links: @node.descendant_links_and_self,
          identities: @node.descendant_identities_and_self
        }
      }
    end
  end
  
  def update
    valid = @node.update_from_params(resource_params)
    
    respond_to do |format|
      format.json {
        render json: {}, status: valid ? :ok : :unprocessable_entity
      }
    end
  end
  
  private
  
    def preload
      @node = Node.find(params[:id]) if params[:id]
    end
    
    def resource_params
      params[:node]
    end
end
