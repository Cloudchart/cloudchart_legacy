class NodesController < ApplicationController
  def index
    @nodes = Node.charts
    
    respond_to do |format|
      format.json { render json: @nodes }
    end
  end
  
  def show
    @node = Node.find(params[:id])
    
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
end