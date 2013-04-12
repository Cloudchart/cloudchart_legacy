class PersonsController < ApplicationController
  def index
    # not_found unless can?(:update, @chart)
    render json: { persons: [] } and return unless user_signed_in?
    
    # Search
    query = params[:q].to_s.strip
    if query.present?
      @persons = current_user.linkedin_client.normalized_people_search(query)
      @persons.map! { |x| Person.new({ type: "ln" }.merge(x)) }
    else
      @persons = []
    end
    
    respond_to { |format|
      format.json {
        render json: { persons: @persons }
      }
    }
  end
end
