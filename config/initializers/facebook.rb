if !defined? FACEBOOK_KEY
  FACEBOOK_KEY = "357925437647513"
  FACEBOOK_SECRET = "656052578bf673df1a10a99f3406bc70"
  FACEBOOK_SCOPE = [
    "email",
    "user_birthday",
    "friends_birthday",
    "user_hometown",
    "friends_hometown",
    "user_location",
    "friends_location",
    "user_education_history",
    "friends_education_history",
    "user_work_history",
    "friends_work_history",
    "user_about_me",
    "friends_about_me",
    "user_relationships",
    "friends_relationships"
  ].join(",")
  
  FACEBOOK_FIELDS_MAPPING = {
    ## General
    id: :external_id,
    link: :profile_url,
    picture: nil,
    
    ## Personal
    first_name: :first_name,
    last_name: :last_name,
    birthday: :birthday,
    gender: :gender,
    hometown: :hometown,
    location: :location,
    
    ## Education, work, bio
    education: :education,
    work: :work,
    bio: :description,
    
    ## Relationships
    relationship_status: :status,
    family: :family
  }
  
  module Koala
    module Facebook
      module GraphAPIMethods
        def normalized_profile(id)
          fetched = get_object(id, fields: FACEBOOK_FIELDS_MAPPING.keys.join(","))
          normalize_profile(fetched)
        end
        
        def normalized_people_search(query)
          fetched = search(query, type: :user, fields: FACEBOOK_FIELDS_MAPPING.keys.join(","))
          (fetched || []).map { |attrs|
            normalize_profile(attrs)
          }
        end
        
        def normalize_profile(fetched)
          attrs = Hash[FACEBOOK_FIELDS_MAPPING.map { |k, v| [v, fetched[k.to_s]] }]
          attrs.delete(nil)
          
          # Picture
          if fetched["picture"] && fetched["picture"]["data"]
            attrs[:picture_url] = fetched["picture"]["data"]["url"]
          end
          
          # Birthday
          attrs[:birthday] = Date.strptime(attrs[:birthday], "%m/%d/%Y") if attrs[:birthday]
          
          # Locations
          [:hometown, :location].each do |k|
            attrs[k] = attrs[k]["name"] if attrs[k]
          end
          
          # TODO: Education, work
          attrs.delete(:education)
          attrs.delete(:work)
          
          # Family
          attrs[:family] = attrs[:family]["data"] if attrs[:family]
          
          attrs
        end
      end
    end
  end
end
