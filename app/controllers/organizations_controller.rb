class OrganizationsController < ApplicationController
  def index
    return unauthorized unless user_signed_in?
    @organizations = current_user.organizations
  end
  
  def create
    return unauthorized unless user_signed_in?
    organization = Organization.where(title: "Test (#{Date.today})").first_or_create
    current_user.access!(organization, :owner!)
    redirect_to organization_path(organization)
  end
  
  def show
    return unauthorized unless can?(:read, @organization)
  end
  
    def preload
      super
      
      @organization = Organization.find(params[:id]) if params[:id]
    end
end
