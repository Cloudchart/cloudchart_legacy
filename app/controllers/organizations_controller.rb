class OrganizationsController < ApplicationController
  def index
    @organizations = current_user.organizations
  end
  
  def create
    organization = Organization.where(title: "Test (#{Date.today})").first_or_create
    current_user.access!(organization, :owner!)
    redirect_to organization_path(organization)
  end
  
  def show
  end
  
    def preload
      super
      
      @organization = Organization.find(params[:id]) if params[:id]
    end
end
