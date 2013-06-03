class ChartsController < ApplicationController
  def new
    return unauthorized unless user_signed_in?
    
    @node = @organization.nodes.new(resource_params)
  end
  
  def create
    return unauthorized unless user_signed_in?
    
    @node = @organization.nodes.create_chart_node(resource_params)
    if @node.valid?
      # current_user.access!(@node, :owner!)
      redirect_to organization_chart_path(@organization, @node)
    else
      render :new
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
