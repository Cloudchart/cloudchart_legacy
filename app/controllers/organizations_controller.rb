class OrganizationsController < ApplicationController
  def index
    return unauthorized unless user_signed_in?
  end
  
  def new
    return unauthorized unless user_signed_in?
    
    @organization = Organization.new
    render :form
  end
  
  def create
    return unauthorized unless user_signed_in?
    
    @organization = Organization.create(resource_params)
    if @organization.valid?
      current_user.access!(@organization, :owner!)
      redirect_to organization_path(@organization)
    else
      render :form
    end
  end
  
  def show
    return unauthorized unless can?(:read, @organization)
  end
  
  def edit
    return unauthorized unless can?(:update, @organization)
    
    render :form
  end
  
  def update
    return unauthorized unless can?(:update, @organization)
    
    if params[:widgets]
      @organization.update_widgets(params[:widgets])
    else
      @organization.update_attributes(resource_params)
    end
    
    if @organization.valid?
      respond_to do |format|
        format.json { render json: {} }
        format.html { redirect_to organization_path(@organization) }
      end
    else
      render :form
    end
  end
  
  private
  
    def preload
      super
      
      @organization = Organization.find(params[:id]) if params[:id]
    end
    
    def resource_params
      params[:organization]
    end
end
