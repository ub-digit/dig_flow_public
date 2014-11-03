class AlertMailer < ActionMailer::Base
  default to: User.where(:mailalerts => true).pluck(:email),
    from: 'noreply@ub.gu.se'

  def quarantine_alert(job, note, current_user, type)
    @job = job
    @note = note
    @current_user = current_user
    @type = type
    mail(
      content_type: "text/html",
      subject: t("mailalerts.subject_prefix") + t("mailalerts." + type + ".subject"))
  end
  
  def restart_alert(job, note, current_user)
    @job = job
    @note = note
    @current_user = current_user
    mail(
      content_type: "text/html",
      subject: t("mailalerts.subject_prefix") + t("mailalerts.restart.subject"))
  end
end
