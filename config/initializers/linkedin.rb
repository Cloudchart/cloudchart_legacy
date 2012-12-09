module LinkedIn
  module Api
    module QueryMethods
      
      def people_search(options = {})
        simple_query("/people-search#{options.delete(:path)}", options)
      end
      
    end
  end
end

if not defined? LINKEDIN_KEY
  LINKEDIN_KEY = "3e3175t1pm1f"
  LINKEDIN_SECRET = "dLrM8zLoyGDfgX7d"
  
  LinkedIn.configure do |config|
    config.token = LINKEDIN_KEY
    config.secret = LINKEDIN_SECRET
  end
end
