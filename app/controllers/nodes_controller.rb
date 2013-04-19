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
        render json: @node.serialized_params
      }
    end
  end
  
  def update
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
      @node = Node.find(params[:id]) if params[:id]
    end
    
    def resource_params
      params[:node]
    end
end
