# RailsAdmin config file. Generated on October 28, 2012 16:49
# See github.com/sferik/rails_admin for more informations

RailsAdmin.config do |config|
  # Set the admin name here (optional second array element will appear in red). For example:
  config.main_app_name = ["Cloudchart", "Admin"]
  
  # RailsAdmin may need a way to know who the current user is]
  config.current_user_method { current_user } # auto-generated
  
  # Label methods
  [:slug, :title].map { |x| config.label_methods << x }
  
  # Models
  config.model "User" do
    object_label_method do
      :email
    end
  end
  
  config.model "Authorization" do
    visible false
  end
  
  config.model "Node" do
    visible false
  end
  
  config.model "Chart" do
    configure :versions do
      hide
    end
    
    configure :nodes do
      hide
    end
  end
  
  config.model "Invitable" do
    visible false
    
    object_label_method do
      :title
    end
    
    configure :invitation do
       hide
    end
  end
  
  config.model "Invitation" do
    object_label_method do
      :title
    end
    
    configure :template do
      # associated_collection_cache_all false
      associated_collection_scope do
        ->(scope) {
          ids = Invitation.distinct(:body_hash).map { |x| Invitation.find_by(body_hash: x) }.map(&:id)
          scope.in(id: ids)
        }
      end
    end
    
    configure :body_hash do
      hide
    end
    
    list do
      configure :_id do
        hide
      end
      
      configure :template do
        hide
      end
      
      configure :invitables do
        hide
      end
    end
    
    edit do 
      configure :users do
        hide
      end
      
      configure :body do
        help "Placeholders: [name], [link]"
      end
    end
    
    show do
      configure :users do
        pretty_value do 
          bindings[:view].render partial: "invited_users", locals: { object: bindings[:object] }
        end
      end
    end
  end
end
