class NodesController < ApplicationController
  def index
    return unauthorized unless can?(:read, @organization)
    @nodes = @organization.nodes.charts
    
    respond_to do |format|
      format.json { render json: @nodes }
    end
  end
  
  def show
    return unauthorized unless can?(:read, @organization)
    
    respond_to do |format|
      format.json {
        render json: @node.serialized_params
      }
    end
  end
  
  def update
    return unauthorized unless can?(:update, @organization)
    
    @node.prepare_params(resource_params)
    @node.save
    
    respond_to do |format|
      format.json {
        if @node.valid?
          render json: {}
        else
          render json: { errors: @node.errors.full_messages }, status: :unprocessable_entity
        end
      }
    end
  end
  
  private
  
    def preload
      super
      
      @organization = Organization.find(params[:organization_id])
      @node = Node.find(params[:id]) if params[:id]
    end
    
    def resource_params
      params[:node]
    end
end
