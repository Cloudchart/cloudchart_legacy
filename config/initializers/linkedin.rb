if !defined? LINKEDIN_KEY
  module LinkedIn
    module Api
      module QueryMethods

        FIELDS_MAPPING = {
          id: :id,
          first_name: :first_name,
          last_name: :last_name,
          :"picture-urls::(original)" => :picture_urls,
          picture_url: :picture_url,
          headline: :headline,
          summary: :description,
          :"site-standard-profile-request" => :profile_url
        }

        def normalized_profile(id)
          fetched = profile(id: id, fields: FIELDS_MAPPING.keys)

          normalize_profile(fetched)
        end

        def normalized_people_search(query)
          fetched = people_search(keywords: CGI.escape(query), path: ":(people:(#{FIELDS_MAPPING.keys.join(",")}),num-results)")

          (fetched.people.all || []).reject { |attrs| attrs.id == "private" }.map { |attrs|
            normalize_profile(attrs)
          }
        end

        def normalize_profile(fetched)
          attrs = Hash[FIELDS_MAPPING.map { |k, v| [v, fetched[k]] }]
          attrs[:external_id] = attrs[:id]

          # Process profile url
          attrs[:profile_url] = attrs[:profile_url].url if attrs[:profile_url]

          # Process picture
          if fetched[:picture_urls] && fetched[:picture_urls][:all]
            attrs[:picture_url] = fetched[:picture_urls][:all].first if fetched[:picture_urls][:all].is_a?(Array)
          end
          attrs.delete(:picture_urls)

          attrs
        end

        def people_search(options = {})
          simple_query("/people-search#{options.delete(:path)}", options)
        end

      end
    end
  end

  LINKEDIN_KEY = "3e3175t1pm1f"
  LINKEDIN_SECRET = "dLrM8zLoyGDfgX7d"

  LinkedIn.configure do |config|
    config.token = LINKEDIN_KEY
    config.secret = LINKEDIN_SECRET
  end
end
