module ApplicationHelper
  def print_status(status)
    content_tag :span, :title => status.name do
      t("statuses."+status.name).gsub(/ /,"&nbsp;").html_safe
    end
  end

  def column_is_metadata?(key)
    case key
    when "title"
      return false
    when "author"
      return false
    when "id"
      return false
    when "user_id"
      return false
    when "status_id"
      return false
    when "catalog_id"
      return false
    when "project_id"
      return false
    else
      return true
    end
  end
end
