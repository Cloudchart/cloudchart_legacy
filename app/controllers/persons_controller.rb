class PersonsController < ApplicationController
  def index
    if user_signed_in?
      @persons = current_user.persons
    else
      @persons = []
    end
    
    respond_to do |format|
      format.html
      format.json {
        render json: { persons: @persons }
      }
    end
  end
  
  def create
    # not_found unless can?(:update, @chart)
    render json: { persons: [] } and return unless user_signed_in?
    
    # Create person by identifier
    if params[:identifier]
      type, external_id = params[:identifier].split(":")
      params = case type
      when "ln"
        current_user.linkedin_client.normalized_profile(external_id)
      when "fb"
      end
      
      current_user.persons.create(params.merge(type: type)) if params
    end
    
    respond_to do |format|
      format.html
      format.json {
        render json: { persons: current_user.persons }
      }
    end
  end
  
  def search
    # not_found unless can?(:update, @chart)
    render json: { persons: [] } and return unless user_signed_in?
    
    # Search
    @persons = []
    @query = params[:search][:q].to_s.strip.gsub(/[^([:alnum:]|\.\s)]/, "")
    
    if @query.present?
      if params[:search][:local]
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
        render json: { persons: @persons }
      }
    end
  end
end
