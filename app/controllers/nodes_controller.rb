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
          nodes: @node.descendant_nodes_and_self,
          links: @node.descendant_links_and_self,
          identities: @node.descendant_identities_and_self,
          persons: @node.descendant_persons_and_self
        }
      }
    end
  end
end