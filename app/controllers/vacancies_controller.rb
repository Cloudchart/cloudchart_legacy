class VacanciesController < ApplicationController
  def index
    return unauthorized unless user_signed_in?
    
    @vacancies = @organization.vacancies
  end
  
  def search
    return unauthorized unless user_signed_in?
    
    # Search
    @vacancies = []
    @query = params[:search][:query].to_s.strip.gsub(/[^([:alnum:]|\.\s)]/, "")
    
    begin
      @vacancies = Vacancy.search(load: true, page: params[:page], per_page: 20) do |search|
        search.query { |query| query.string @query, default_operator: "AND" }
        # search.sort  { |sort| sort.by :created_at, "desc" }
      end
    # rescue Tire::Search::SearchRequestFailed
    #   
    end
    
    respond_to do |format|
      format.json {
        render json: { vacancies: @vacancies }
      }
    end
  end
  
  def new
    return unauthorized unless user_signed_in?
    
    @vacancy = @organization.vacancies.new(resource_params)
    render :form
  end
  
  def create
    return unauthorized unless user_signed_in?
    
    @vacancy = @organization.vacancies.create(resource_params)
    if @vacancy.valid?
      redirect_to organization_vacancy_path(@organization, @vacancy)
    else
      render :form
    end
  end
  
  def show
    return unauthorized unless user_signed_in?
  end
  
  def edit
    return unauthorized unless user_signed_in?
    render :form
  end
  
  def update
    return unauthorized unless can?(:update, @organization)
    
    if resource_params
      @vacancy.update_attributes(resource_params)
    end
    
    if @vacancy.valid?
      redirect_to organization_vacancy_path(@organization, @vacancy)
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
