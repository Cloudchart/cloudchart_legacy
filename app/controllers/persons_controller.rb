class PersonsController < ApplicationController
  def index
    # not_found unless can?(:update, @chart)
    
    @client = current_user.linkedin_client
    @persons = @client.people_search(keywords: params[:query])
    
    respond_to { |format|
      format.json {
        render json: { persons: @persons.people.all }
      }
    }
  end
  
  private
  
    def preload
      @chart ||= Chart.find_by_slug_or_id(params[:chart_id]) if params[:chart_id].present?
      
      super
    end
  
end