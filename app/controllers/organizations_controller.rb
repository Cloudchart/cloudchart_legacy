class OrganizationsController < ApplicationController
  def index
    @organizations = Organization.all
  end
  
  def create
    organization = Organization.where(title: "Test").first_or_create
    redirect_to organization_path(organization)
  end
  
  def show
  end
  
    def preload
      super
      
      @organization = Organization.find(params[:id]) if params[:id]
    end
end
