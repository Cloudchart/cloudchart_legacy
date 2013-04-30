if !defined? LINKEDIN_KEY
  LINKEDIN_KEY = "3e3175t1pm1f"
  LINKEDIN_SECRET = "dLrM8zLoyGDfgX7d"
  LINKEDIN_SCOPE = [
    "r_emailaddress",
    "r_basicprofile",
    "r_fullprofile",
    "r_contactinfo",
    "r_network"
  ].join(" ")
  
  LINKEDIN_FIELDS_MAPPING = {
    ## General
    id: :external_id,
    :"site-standard-profile-request" => :profile_url,
    :"picture-urls::(original)" => :picture_urls,
    picture_url: :picture_url,
    
    ## Personal
    first_name: :first_name,
    last_name: :last_name,
    # :"formatted-name" => :formatted_name,
    :"date-of-birth" => :birthday,
    # gender: :gender,
    # hometown: :hometown,
    :"location:(name)" => :location,
    
    ## Contacts, networks
    :"phone-numbers" => :phones,
    # :"twitter-accounts" => :twitters,
    
    ## Education, work, skills, bio
    educations: :education,
    positions: :work,
    skills: :skills,
    summary: :description
  }
  
  LinkedIn.configure do |config|
    config.token = LINKEDIN_KEY
    config.secret = LINKEDIN_SECRET
  end
  
  module LinkedIn
    module Api
      module QueryMethods
        def normalized_profile(id)
          fetched = profile(id: id, fields: LINKEDIN_FIELDS_MAPPING.keys)
          normalize_profile(fetched)
        end
        
        def normalized_people_search(query)
          fetched = people_search(keywords: CGI.escape(query), path: ":(people:(#{LINKEDIN_FIELDS_MAPPING.keys.join(",")}),num-results)")
          
          (fetched.people.all || []).reject { |attrs| attrs.id == "private" }.map { |attrs|
            normalize_profile(attrs)
          }
        end
        
        def normalize_profile(fetched)
          attrs = Hash[LINKEDIN_FIELDS_MAPPING.map { |k, v| [v, fetched[k]] }]
          attrs[:type] = "Linkedin"
          attrs.delete(nil)
          
          # Picture
          if fetched[:picture_urls] && fetched[:picture_urls][:all]
            attrs[:picture_url] = fetched[:picture_urls][:all].first if fetched[:picture_urls][:all].is_a?(Array)
          end
          attrs.delete(:picture_urls)
          
          # Profile url
          attrs[:profile_url] = attrs[:profile_url].url if attrs[:profile_url]
          
          # Birthday
          attrs[:birthday] = Date.parse(%w(year month day).map { |k| attrs[:birthday][k] }.compact.join("-")) rescue nil if attrs[:birthday]
          
          # Phones
          if attrs[:phones]
            phones = attrs[:phones].all
            attrs[:phones] = phones.map { |x|
              {
                type: x.phone_type,
                number: x.phone_number
              }.stringify_keys
            }
          end
          
          # Education
          if attrs[:education] && attrs[:education].all
            educations = attrs[:education].all
            attrs[:education] = educations.map { |x|
              education = {}
              education[:name] = x.school_name
              education[:degree] = x.degree if x.degree
              education[:concentration] = x.field_of_study if x.field_of_study
              education[:start_year] = x.start_date.year if x.start_date
              education[:end_year] = x.end_date.year if x.end_date
              education.stringify_keys
            }
          end
          
          # Work
          if attrs[:work] && attrs[:work].all
            works = attrs[:work].all
            attrs[:work] = works.map { |x|
              work = {}
              work[:employer] = { id: x.company.id, name: x.company.name }.stringify_keys if x.company
              work[:position] = x.title if x.title
              work[:description] = x.summary if x.summary
              work[:start_date] = %w(year month day).map { |k| x.start_date[k] }.compact.join("-") if x.start_date
              work[:end_date] = %w(year month day).map { |k| x.end_date[k] }.compact.join("-") if x.end_date
              work.stringify_keys
            }
          end
          
          # Skills
          if attrs[:skills]
            attrs[:skills] = attrs[:skills].all.map(&:skill).map(&:name)
          end
          
          attrs.stringify_keys
        end
      end
    end
  end
end
