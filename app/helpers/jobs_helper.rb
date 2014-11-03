module JobsHelper


  def copyright_for_job(job)
    if job.copyright
      t("mets_data.copyright_status."+DigFlow::Application.config.copyright[job.copyright][:name])
    else
      if job.project.copyright
        t("mets_data.copyright_status.default_from_project") + " (" + copyright_for(job.project) + ")"
      else
        t("mets_data.copyright_status.default_from_config") + " (" + t("mets_data.copyright_status."+DigFlow::Application.config.copyright[job.project.copyright_value][:name]) + ")"
      end
    end
  end
end
