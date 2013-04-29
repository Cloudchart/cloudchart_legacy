class OrganizationsController < ApplicationController
  def index
    organization = Organization.where(title: ["Test 1", "Test 2"].sample).first_or_create
    redirect_to organization_persons_path(organization)
  end
end
