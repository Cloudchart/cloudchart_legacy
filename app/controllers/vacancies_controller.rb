class VacanciesController < ApplicationController
  def new
    return unauthorized unless user_signed_in?
    
    @vacancy = @organization.vacancies.new(resource_params)
    render :form
  end
  
  def create
    return unauthorized unless user_signed_in?
    
    @vacancy = @organization.vacancies.create(resource_params)
    if @vacancy.valid?
      redirect_to organization_path(@organization)
    else
      render :form
    end
  end
  
  private
  
    def preload
      super
      
      @organization = Organization.find(params[:organization_id])
      @vacancy = Vacancy.find(params[:id]) if params[:id]
    end
    
    def resource_params
      params[:vacancy]
    end
end
