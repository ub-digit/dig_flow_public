module ProjectsHelper
  def copyrights_list
    copyrights = DigFlow::Application.config.copyright.keys.map do |x|
      if x
        [t("mets_data.copyright_status."+DigFlow::Application.config.copyright[x][:name]), x]
      else
        [t("mets_data.copyright_status.default_from_config")+t("mets_data.copyright_status."+DigFlow::Application.config.copyright[x][:name]), x]
      end
    end
  end
  
  def copyright_for(project)
    if project.copyright_value
      t("mets_data.copyright_status."+DigFlow::Application.config.copyright[project.copyright_value][:name])
    else
      t("mets_data.copyright_status.default_from_config")+t("mets_data.copyright_status."+DigFlow::Application.config.copyright[project.copyright_value][:name])
    end
  end
end
