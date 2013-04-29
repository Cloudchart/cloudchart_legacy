class PersonsController < ApplicationController
  def index
    if user_signed_in?
      if params[:filters]
        if params[:filters].include?("all")
          @persons = current_user.identities
        else
          @persons = @organization.identities
        end
        
        @persons = @persons.used if params[:filters].include?("used") && !params[:filters].include?("unused")
        @persons = @persons.unused if params[:filters].include?("unused") && !params[:filters].include?("used")
      else
        @persons = @organization.identities
      end
    end
    
    respond_to do |format|
      format.html
      format.json {
        render json: { persons: @persons.map(&:to_person) || [] }
      }
    end
  end
  
  def search
    # not_found unless can?(:update, @chart)
    render json: { persons: [] } and return unless user_signed_in?
    
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
            search.query { |query| query.string @query }
            # search.sort  { |sort| sort.by :created_at, "desc" }
          end
          
          @persons.concat(persons.to_a)
        rescue Tire::Search::SearchRequestFailed
          
        end
      end
    end
    
    respond_to do |format|
      format.json {
        render json: { persons: @persons }
      }
    end
  end
  
  def show
    # not_found unless can?(:update, @chart)
    render json: { person: nil } and return unless user_signed_in?
    
    # Find or create person by identifier
    person = Person.find_or_create_with_identifier(params[:id], current_user)
    person.add_to_organization(@organization)
    
    respond_to do |format|
      format.html
      format.json {
        render json: { person: person }
      }
    end
  end
  
  def update
    # not_found unless can?(:update, @chart)
    render json: { person: nil } and return unless user_signed_in?
    
    # Find or create person by identifier
    person = Person.find_or_create_with_identifier(params[:id], current_user)
    identity = person.add_to_organization(@organization)
    
    # Update identity
    is_starred = resource_params.delete(:is_starred)
    if !is_starred.nil?
      identity.set(:is_starred, is_starred)
    end
    
    # Mark as used
    # TODO: Unmock
    is_used = resource_params.delete(:is_used)
    if is_used
      person.use_in_organization(@organization, Node.new)
    end
    
    # Update person
    if resource_params.any?
      person.update_attributes(resource_params)
      
      # Reload nested person
      identity.entity.reload
    end
    
    respond_to do |format|
      format.html
      format.json {
        render json: { person: identity.to_person }
      }
    end
  end
  
  private
  
    def preload
      super
      
      @organization = Organization.find(params[:organization_id])
    end
    
    def resource_params
      params[:person]
    end
end
