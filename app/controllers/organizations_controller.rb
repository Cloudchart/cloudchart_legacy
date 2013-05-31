class OrganizationsController < ApplicationController
  def index
    return unauthorized unless user_signed_in?
  end
  
  def create
    return unauthorized unless user_signed_in?
    
    @organization = Organization.create(resource_params)
    if @organization.valid?
      current_user.access!(@organization, :owner!)
      redirect_to organization_path(@organization)
    else
      render :new
    end
  end
  
  def show
    return unauthorized unless can?(:read, @organization)
  end
  
    def preload
      super
      
      @organization = Organization.find(params[:id]) if params[:id]
    end
    
    def resource_params
      params[:organization]
    end
end
