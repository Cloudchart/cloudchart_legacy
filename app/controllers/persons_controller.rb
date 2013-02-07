class PersonsController < ApplicationController
  def index
    not_found unless can?(:update, @chart)
    
    @client = current_user.linkedin_client
    @persons = @client.people_search(keywords: params[:q], path: ":(people:(id,first-name,last-name,picture-url,headline),num-results)")
    
    respond_to { |format|
      format.json {
        render json: { persons: (@persons.people.all || []).reject { |x| x.id == "private" } }
      }
    }
  end
  
  def profile
    not_found unless can?(:update, @chart)
    
    respond_to { |format|
      format.html {
        render partial: "/persons/profile", locals: { chart: @chart, person: @chart.load_person(params[:person_id]) }
      }
    }
  end
  
  private
  
    def preload
      @chart ||= Chart.find_by_slug_or_id(params[:chart_id]) if params[:chart_id].present?
      
      super
    end
  
end