class ApplicationMailer < ActionMailer::Base
  default from: "CloudChart Team <staff@cloudorgchart.com>"
  
  def share(current_user, chart, email, params)
    name = current_user ? current_user.name : t("common.anonymous")
    mail(
      to: email,
      subject: I18n.t("charts.share.mail.subject", name: name, chart: chart.title, link: params[:link])
    ) do |format|
      format.text do
        I18n.t("charts.share.mail.body", link: params[:link])
      end
    end
  end
  
  def invite(current_user, email, params)
    name = current_user ? current_user.name : t("common.anonymous")
    mail(
      to: email,
      subject: I18n.t("users.invite.mail.subject", name: name)
    ) do |format|
      format.text do
        I18n.t("users.invite.mail.body", link: params[:link])
      end
    end
  end
  
  def custom_invite(email, params)
    mail(
      to: email,
      from: params[:from],
      subject: params[:subject],
    ) do |format|
      format.text do
        [:name, :link].map { |x| params[:body].gsub!("[#{x}]", params[x]) }
        params[:body]
      end
    end
  end
end
