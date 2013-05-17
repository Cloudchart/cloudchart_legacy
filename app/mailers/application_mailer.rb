class ApplicationMailer < ActionMailer::Base
  default from: "CloudChart Team <staff@cloudorgchart.com>"
  
  def profile(current_user, email, params)
    name = current_user ? current_user.name : t("app.anonymous")
    mail(
      to: email,
      subject: I18n.t("mailer.profile.subject")
    ) do |format|
      format.text do
        I18n.t("mailer.profile.body", name: name, link: params[:link])
      end
    end
  end
end
