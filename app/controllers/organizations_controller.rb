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
    
    @widgets = @organization.initialize_widgets
  end
  
  def page
    return unauthorized unless can?(:read, @organization)
    
    @widgets = @organization.initialize_widgets[params[:page]]
    if !@widgets
      redirect_to organization_path(@organization) and return
    end
  end
  
  def edit
    return unauthorized unless can?(:update, @organization)
  end
  
  def update
    return unauthorized unless can?(:update, @organization)
    
    # Upload
    if params[:upload]
      picture = @organization.uploads.create(picture: params[:upload])
      
      respond_to do |format|
        format.json { render json: picture }
      end and return
    end
    
    # Picture
    if params[:picture]
      @organization.picture = params[:picture]
      @organization.save!
    end
    
    if resource_params
      # Widgets
      if resource_params[:widgets].present?
        @organization.update_widgets(JSON.parse(resource_params.delete(:widgets)))
      end
      
      # Attributes
      @organization.update_attributes(resource_params)
    end
    
    if @organization.valid?
      respond_to do |format|
        format.json { render json: @organization }
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
