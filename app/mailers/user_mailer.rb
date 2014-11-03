class UserMailer < ActionMailer::Base
  default from: "noreply@ub.gu.se"

  def welcome_email(user,password)
    @user = user
    @password = password
    mail(
      to: @user.email,
      content_type: "text/html",
      subject: t("mailalerts.welcome.subject")
      )
  end
end
