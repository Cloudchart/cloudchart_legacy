# RailsAdmin config file. Generated on October 28, 2012 16:49
# See github.com/sferik/rails_admin for more informations

RailsAdmin.config do |config|
  # Set the admin name here (optional second array element will appear in red). For example:
  config.main_app_name = ["Cloudchart", "Admin"]
  
  # RailsAdmin may need a way to know who the current user is]
  config.current_user_method { current_user } # auto-generated
  
  # Label methods
  config.label_methods << "slug"
  
  # Models
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
  
  config.model "Invitation" do
    object_label_method do
      :title
    end
    
    configure :template do
      # associated_collection_cache_all false
      associated_collection_scope do
        ->(scope) {
          # TODO
          scope#.distinct(:body_hash)
        }
      end
    end
    
    configure :body_hash do
      hide
    end
  end
end
