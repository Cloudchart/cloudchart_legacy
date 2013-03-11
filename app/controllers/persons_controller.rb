class PersonsController < ApplicationController
  def index
    not_found unless can?(:update, @chart)
    render json: { persons: [] } and return unless user_signed_in?
    
    @client = current_user.linkedin_client
    @persons = @client.people_search(keywords: CGI.escape(params[:q]), path: ":(people:(id,first-name,last-name,picture-url,headline),num-results)")
    
    respond_to { |format|
      format.json {
        render json: { persons: (@persons.people.all || []).reject { |x| x.id == "private" } }
      }
    }
  end
  
  def edit
    @partial ||= can?(:edit, @chart) ?  "/persons/autocomplete" :  "/persons/profile"
    @title = params[:id]
    
    profile
  end
  
  def profile
    @partial ||= "/persons/profile"
    @title ||= params[:person_id]
    
    match = @title.scan(/@([^,]*),(.*)$/).first
    @note = match.last.strip if match
    
    @person = @chart.find_person(@title)
    @person.fetch! if @person
    
    respond_to { |format|
      format.html {
        render partial: @partial, locals: {
          title: @title,
          chart: @chart,
          note: @note,
          person: @person
        }
      }
    }
  end
  
  private
  
    def preload
      @chart ||= Chart.find_by_slug_or_id(params[:chart_id]) if params[:chart_id].present?
      not_found if !@chart && params[:chart_id].present?
      
      super
    end
  
end