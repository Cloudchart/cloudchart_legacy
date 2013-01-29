class ApplicationMailer < ActionMailer::Base
  default from: "noreply@cloudorgchart.com"
  
  def share(current_user, chart, email, params)
    mail(
      to: email,
      subject: I18n.t("charts.share.mail.subject", name: current_user.name, chart: chart.title)
    ) do |format|
      format.text do
        I18n.t("charts.share.mail.body", link: params[:link])
      end
    end
  end
end
