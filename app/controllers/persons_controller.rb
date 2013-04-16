class PersonsController < ApplicationController
  def index
  end
  
  def search
    # not_found unless can?(:update, @chart)
    render json: { persons: [] } and return unless user_signed_in?
    
    # Search
    @persons = []
    @query = params[:q].to_s.strip.gsub(/[^([:alnum:]|\.\s)]/, "")
    
    if @query.present?
      begin
        persons = Person.search({ load: true, page: params[:page], per_page: 20 }) { |search|
          search.query { |query|
            query.string @query
          }
          
          # search.sort  { |sort|
          #   sort.by :created_at, "desc"
          # }
        }
        @persons.concat(persons.to_a)
      # rescue Tire::Search::SearchRequestFailed => e
      #   redirect_to root_path, alert: e.message and return
      end
      
      if current_user.linkedin?
        persons = current_user.linkedin_client.normalized_people_search(@query)
        persons.map! { |x| Person.new({ type: "ln" }.merge(x)) }
        @persons.concat(persons)
      end
      
      if current_user.facebook?
        persons = current_user.facebook_client.normalized_people_search(@query)
        persons.map! { |x| Person.new({ type: "fb" }.merge(x)) }
        @persons.concat(persons)
      end
    end
    
    respond_to do |format|
      format.json {
        render json: @persons
      }
    end
  end
end
