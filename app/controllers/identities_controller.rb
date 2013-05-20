class IdentitiesController < ApplicationController
  def index
    return unauthorized unless can?(:update, @organization)
    
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
    
    respond_to do |format|
      format.json {
        render json: { persons: @persons.map(&:to_person) || [] }
      }
    end
  end
  
  def new
    return unauthorized unless can?(:update, @organization)
    @person = Person.new
    
    respond_to do |format|
      format.html {
        render layout: false
      }
    end
  end
  
  def create
    return unauthorized unless can?(:update, @organization)
    @person = Person.find_or_initialize_with_email(resource_params[:email])
    
    # Create person
    if @person.new_record?
      @person.update_attributes(resource_params)
      @person.save!
      @person.use_in_organization(@organization, Node.new)
      
      # Send profile email
      ApplicationMailer.profile(current_user, @person.email, {
        link: edit_person_url(id: @person.id, token: @person.token.digest)
      }).deliver
    end
    
    respond_to do |format|
      format.html {
        redirect_to organization_path(@organization)
      }
      format.json {
        render json: { person: @person }
      }
    end
  end
  
  def show
    return unauthorized unless can?(:update, @organization)
    
    # Find or create person by identifier
    @person = Person.find_or_create_with_identifier(params[:id], current_user)
    @person.add_to_organization(@organization)
    
    respond_to do |format|
      format.html
      format.json {
        render json: { person: @person }
      }
    end
  end
  
  def manage
    return unauthorized unless can?(:update, @organization)
    
    # Find or create person by identifier
    @person = Person.find_or_create_with_identifier(params[:id], current_user)
    
    respond_to do |format|
      format.html {
        render layout: false
      }
    end
  end
  
  def update
    return unauthorized unless can?(:update, @organization)
    
    # Find or create person by identifier
    @person = Person.find_or_create_with_identifier(params[:id], current_user)
    identity = @person.add_to_organization(@organization)
    
    # Update identity
    is_starred = resource_params.delete(:is_starred)
    if !is_starred.nil?
      identity.set(:is_starred, is_starred)
    end
    
    # Mark as used
    # TODO: Unmock
    is_used = resource_params.delete(:is_used)
    if is_used
      @person.use_in_organization(@organization, Node.new)
    end
    
    respond_to do |format|
      format.json {
        render json: { person: identity.to_person }
      }
    end
  end
  
  def invite
    return unauthorized unless can?(:update, @organization)
    
    # Find or create person by identifier
    @person = Person.find_or_create_with_identifier(params[:id], current_user)
    
    # Send profile email
    ApplicationMailer.profile(current_user, params[:person][:email], {
      link: edit_person_url(id: @person.id, token: @person.token.digest)
    }).deliver
    
    respond_to do |format|
      format.html {
        redirect_to organization_path(@organization)
      }
      format.json {
        render json: { person: @person }
      }
    end
  end
  
  def destroy
    return unauthorized unless can?(:update, @organization)
    
    # Find or create person by identifier
    @person = Person.find_or_create_with_identifier(params[:id], current_user)
    identity = @person.find_in_organization(@organization)
    identity.destroy if identity
    
    respond_to do |format|
      format.html
      format.json {
        render json: { }
      }
    end
  end
  
  private
  
    def preload
      super
      
      @organization = Organization.find(params[:organization_id]) if params[:organization_id]
    end
    
    def resource_params
      params[:person]
    end
end
