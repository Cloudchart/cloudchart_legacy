class PersonsController < ApplicationController
  def search
    return unauthorized unless user_signed_in?
    
    # Search
    @persons = []
    @query = params[:search][:query].to_s.strip.gsub(/[^([:alnum:]|\.\s)]/, "")
    
    if @query.present?
      case params[:search][:provider]
      when "Linkedin"
        if current_user.linkedin?
          persons = current_user.linkedin_client.normalized_people_search(@query)
          persons.map! { |x| Person.find_or_create_with_params(x, current_user) }
          @persons.concat(persons)
        end
      when "Facebook"
        if current_user.facebook?
          persons = current_user.facebook_client.normalized_people_search(@query)
          persons.map! { |x| Person.find_or_create_with_params(x, current_user) }
          @persons.concat(persons)
        end
      else
        begin
          persons = Person.search(load: true, page: params[:page], per_page: 20) do |search|
            search.query { |query| query.string @query, default_operator: "AND" }
            # search.sort  { |sort| sort.by :created_at, "desc" }
          end
          
          @persons.concat(persons.to_a)
        # rescue Tire::Search::SearchRequestFailed
        #   
        end
      end
    end
    
    respond_to do |format|
      format.json {
        render json: { persons: @persons }
      }
    end
  end
  
  def edit
    @person = Person.find(params[:id])
    return unauthorized unless can?(:update, @person)
  end
  
  def update
    @person = Person.find(params[:id])
    return unauthorized unless can?(:update, @person)
    
    # Update person
    if resource_params.any?
      @person.prepare_params(resource_params)
      @person.save
    end
    
    respond_to do |format|
      format.html {
        if @person.valid?
          redirect_to edit_person_path(id: @person.id, token: params[:token])
        else
          render :edit
        end
      }
    end
  end
  
  private
  
    def resource_params
      params[:person]
    end
    
    def unauthorized
      respond_to do |format|
        format.html {
          render :unauthorized
        }
      end
    end
end
