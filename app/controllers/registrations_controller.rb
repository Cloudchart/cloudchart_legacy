class RegistrationsController < Devise::RegistrationsController
  def profile
    respond_to do |format|
      format.html { render partial: "/shared/profile" }
      format.json { render json: current_user }
    end
  end
  
  def edit
    @cls = "users"
    super
  end
  
  def update
    @cls = "users"
    super
  end
end
