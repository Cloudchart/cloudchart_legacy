if !defined? FACEBOOK_KEY
  if Rails.env.development?
    FACEBOOK_KEY = "191576587661270"
    FACEBOOK_SECRET = "765a9ac73d1f2e35df770dd120e9a810"
  else
    FACEBOOK_KEY = "357925437647513"
    FACEBOOK_SECRET = "656052578bf673df1a10a99f3406bc70"
  end
  
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
        
        def normalized_connections
          fetched = get_object("/me/friends", fields: FACEBOOK_FIELDS_MAPPING.keys.join(","))
          (fetched || []).map { |attrs|
            normalize_profile(attrs)
          }
        end
        
        def normalize_profile(fetched)
          attrs = Hash[FACEBOOK_FIELDS_MAPPING.map { |k, v| [v, fetched[k.to_s]] }]
          attrs[:type] = "Facebook"
          attrs.delete(nil)
          
          # Picture
          if fetched["picture"] && fetched["picture"]["data"]
            attrs[:picture_url] = fetched["picture"]["data"]["url"]
          end
          
          # Birthday
          attrs[:birthday] = Date.strptime(attrs[:birthday], "%m/%d/%Y") rescue nil if attrs[:birthday]
          
          # Locations
          [:hometown, :location].each do |k|
            attrs[k] = attrs[k]["name"] if attrs[k]
          end
          
          # Education
          if attrs[:education]
            educations = attrs[:education]
            attrs[:education] = educations.map { |x|
              education = {}
              education[:type] = x["type"] if x["type"]
              education[:name] = x["school"]["name"] if x["school"]
              education[:degree] = x["degree"]["name"] if x["degree"]
              education[:concentration] = x["concentration"].map { |c| c["name"] }.join(", ") if x["concentration"]
              education[:end_year] = x["year"]["name"].to_i if x["year"]
              education.stringify_keys
            }
          end
          
          # Work
          if attrs[:work]
            works = attrs[:work]
            attrs[:work] = works.map { |x|
              work = {}
              if x["employer"]
                work[:employer_id] = x["employer"]["id"]
                work[:employer_name] = x["employer"]["name"]
              end
              work[:position] = x["position"]["name"] if x["position"]
              work[:description] = x["description"] if x["description"]
              work[:start_date] = x["start_date"] if x["start_date"]
              work[:end_date] = x["end_date"] if x["end_date"]
              work.stringify_keys
            }
          end
          
          # Family
          attrs[:family] = attrs[:family]["data"] if attrs[:family]
          
          attrs.stringify_keys
        end
      end
    end
  end
end
