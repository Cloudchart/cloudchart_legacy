if !defined? FACEBOOK_KEY
  FACEBOOK_KEY = "357925437647513"
  FACEBOOK_SECRET = "656052578bf673df1a10a99f3406bc70"
  FACEBOOK_FIELDS_MAPPING = {
    id: :id,
    first_name: :first_name,
    last_name: :last_name,
    bio: :description,
    link: :profile_url
  }
  
  module Koala
    module Facebook
      module GraphAPIMethods
        def normalized_profile(id)
          fetched = get_object(id, fields: (FACEBOOK_FIELDS_MAPPING.keys + ["picture", "work"]).join(","))
          normalize_profile(fetched)
        end
        
        def normalized_people_search(query)
          fetched = search(query, type: :user, fields: (FACEBOOK_FIELDS_MAPPING.keys + ["picture", "work"]).join(","))
          (fetched || []).map { |attrs|
            normalize_profile(attrs)
          }
        end
        
        def normalize_profile(fetched)
          attrs = Hash[FACEBOOK_FIELDS_MAPPING.map { |k, v| [v, fetched[k.to_s]] }]
          attrs[:external_id] = attrs[:id]
          attrs.delete(:id)
          
          # Process picture
          if fetched["picture"] && fetched["picture"]["data"]
            attrs[:picture_url] = fetched["picture"]["data"]["url"]
          end
          
          # Process work
          if fetched["work"]
            work = fetched["work"].first
            attrs[:headline] = "#{work["position"]["name"]} at #{work["employer"]["name"]}"
          end
          
          attrs
        end
      end
    end
  end
end
