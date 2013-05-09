class OmniauthController < Devise::OmniauthCallbacksController
  include Devise::Controllers::Rememberable

  def linkedin
    oauthorize "Linkedin"
  end

  def facebook
    oauthorize "Facebook"
  end

  def passthru
    not_found
  end

  private

    def oauthorize(kind)
      begin
        @user = find_for_ouath(kind, env["omniauth.auth"], current_user)
      rescue => e
        # @user = nil
        # render "/users/error", locals: { notice: e.message }
        
        flash[:alert] = e.message
        if session[:redirect_to]
          redirect_to session.delete(:redirect_to)
        else
          redirect_to root_path
        end
      end

      if @user
        # flash[:notice] = I18n.t "devise.omniauth_callbacks.success", kind: kind
        session["devise.#{kind.downcase}_data"] = env["omniauth.auth"]

        remember_me(@user)
        @user.remember_me!

        sign_in @user
        # render "/users/success"

        if session[:redirect_to]
          sign_in @user
          redirect_to session.delete(:redirect_to)
        else
          sign_in_and_redirect @user, event: :authentication
        end
      end
    end

    def find_for_ouath(provider, access_token, resource = nil)
      auth = {
        uid: access_token["uid"].to_s,
        token: access_token["credentials"]["token"],
        secret: access_token["credentials"]["secret"],
        name: access_token["info"]["name"] || access_token["info"]["email"] || "",
        picture: access_token["info"]["image"],
        email: nil,
        link: nil
      }

      case provider
      when "Linkedin"
        auth[:email] = access_token["info"]["email"]
        auth[:link] = access_token["info"]["urls"].first.last
      when "Facebook"
        auth[:email] = access_token["info"]["email"]
        auth[:link] = access_token["info"]["urls"].first.last
      else
        raise "Provider #{provider} not handled"
      end

      user = User.where("authorizations.provider" => provider, "authorizations.uid" => auth[:uid]).first
      if user
        authorization = user.authorizations.where(provider: provider, uid: auth[:uid]).first
      else
        authorization = nil
      end

      # Not signed
      if resource.nil?
        user = nil

        # Auth found
        if authorization && !authorization.user.nil?
          user = authorization.user

        # Auth without user
        elsif authorization && authorization.user.nil?
          authorization.destroy
          authorization = nil
        end

        # Not signed, find or create by email
        if user.nil? && auth[:email].present?
          user = find_for_oauth_by_email(auth[:email])
          if user.new_record?
            user.name = auth[:name]
            user.save!
          end
        end

      # Signed
      else
        user = resource

        # Auth belongs to another user
        if authorization && !authorization.user.nil? && authorization.user != resource
          raise t("user.failure", kind: provider)
        end
      end

      raise t("user.wrong_auth") if user.nil?

      authorization = user.authorizations.find_by_uid(auth[:uid])
      if authorization.nil?
        authorization = user.authorizations.build(provider: provider)
      end

      # Update auth
      auth.delete(:email)
      auth.delete(:picture)
      authorization.update_attributes(auth)

      # Update user
      if auth[:picture].present?
        # Get picture by API
        attrs = user.linkedin_client.normalized_profile(user.linkedin.uid) rescue nil
        auth[:picture] = attrs[:picture_url] if attrs && attrs[:picture_url]

        user.picture = URI.parse(auth[:picture])
        user.save
      end

      # Run import in background
      Importer.perform_async(user.id, provider)
      user
    end

    def find_for_oauth_by_email(email)
      if user = User.find_by_email(email)
        user
      else
        user = User.new(email: email, password: Devise.friendly_token[0,20]) 
      end

      user
    end
end
