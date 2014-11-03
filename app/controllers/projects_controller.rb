class ProjectsController < ApplicationController
  before_filter :login_if_not_admin, :except => [:index, :show]

  def index
    @prioritized_jobs = Job.where("priority <> 0").where("status_id <> ?", Status.find_by_name("done").id).where(:deleted_at => nil)
    @projects_done = Project.where(:deleted_at => nil).order("id DESC").select { |x| x.is_done? }
    @projects_active = Project.where(:deleted_at => nil).order("id DESC").select { |x| !x.is_done? }
  end

  def show
    @project = Project.find(params[:id])
    params[:view] = params[:view] || cookies[:view] || DigFlow::Application.config.filter_views.first[:name]
    params[:project_id] = @project.id
    params[:reverse] = (params[:reverse] == "true" ? true : false)
    params[:quarantined] = (params[:quarantined] == "true" ? true : params[:quarantined] == "false" ? false : nil)
    if params[:search].blank?
      @jobs = @project.jobs.where(:deleted_at => nil)
    else
      @jobs = @project.jobs.search(params[:search]).where(:deleted_at => nil)
    end
    @quarantined_job_count = @jobs.where(:quarantined => true).count

    status_ids = jobgroup_status_ids

    @jobs = @jobs.where(:status_id => status_ids) unless status_ids.blank?
    @jobs = @jobs.where(:user_id => params[:user_id]) unless params[:user_id].blank?
    @jobs = @jobs.where(:project_id => params[:project_id]) unless params[:project_id].blank?
    @jobs = @jobs.where(:quarantined => params[:quarantined]) unless params[:quarantined].blank?
    if params[:sort_column].blank?
      @jobs = @jobs.order("id DESC")
    else
      @jobs = @jobs.order("#{params[:sort_column]} #{params[:reverse] ? "DESC" : "ASC"}")
    end
    
    #Filter parameters for view
    @view = DigFlow::Application.config.filter_views.select {|view| view[:name] == params[:view]}[0]
    @view[:filters].each do |key,filter|
      @jobs = @jobs.where(key => filter)
    end
    

    @per_page = params[:per_page] || cookies[:per_page] || 25 # get hits per page value from selection or cookie
    cookies.permanent[:per_page] = @per_page
    @jobs = @jobs.paginate(:page => params[:page], :per_page => @per_page)
    
    cookies.permanent[:view] = @view[:name]
  end
  
  def new
    @project = Project.new
    @copyrights = copyrights_list
  end

  def create
    params[:project].delete_if { |k,v| params[:project][k].blank? }
    @project = Project.new(params[:project])
    if @project.save
      redirect_to :action => 'index'
      return
    end
    @copyrights = copyrights_list
    render :action => 'new'
  end

  def edit
    @project = Project.find(params[:id])
    @copyrights = copyrights_list
  end

  def update
    params[:project].delete_if { |k,v| params[:project][k].blank? }
    @project = Project.find(params[:id])
    params[:project][:copyright] ||= nil
    if @project.update_attributes(params[:project])
      redirect_to :action => 'show'
      return
    end
    @copyrights = copyrights_list
    render :action => 'edit'
  end
  def delete
    @project = Project.find(params[:id])
    @project.update_attribute( :deleted_at, Time.now) if @project.is_empty?
    redirect_to projects_path
  end

  private
  def copyrights_list
    copyrights = DigFlow::Application.config.copyright.keys.map do |x|
      if x
        [t("mets_data.copyright_status."+DigFlow::Application.config.copyright[x][:name]), x]
      else
        [t("mets_data.copyright_status.default_from_config")+t("mets_data.copyright_status."+DigFlow::Application.config.copyright[x][:name]), x]
      end
    end
  end

  def jobgroup_status_ids
    @current_jobgroup = DigFlow::Application.config.project_jobgroups.select { |x| x[:name] == params[:selected]}
    statuses = Array.new
    status_ids = Array.new
    if(!@current_jobgroup.empty?)
      statuses = @current_jobgroup.first[:statuses]
      if !statuses.blank?
        statuses.each do |x|
          status_ids << Status.find_by_name(x).id
        end
      end
    else
    end
    return status_ids
  end

end
