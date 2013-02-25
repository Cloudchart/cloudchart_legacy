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
    show do
      configure :versions do
        hide
      end
      
      configure :nodes do
        hide
      end
    end
    
    edit do
      configure :versions do
        hide
      end
      
      configure :nodes do
        hide
      end
    end
  end
end
