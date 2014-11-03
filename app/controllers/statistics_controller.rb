class StatisticsController < ApplicationController

  before_filter :login_if_not_admin
  layout false, :only => [:print]

  def index
    #old_logger = ActiveRecord::Base.logger
    #ActiveRecord::Base.logger = nil
    
    @jobs_total_count = Job.all.count

    #Get jobgroups from config file
    @jobgroups_statuses = {}
    @jobgroups_statuses = get_jobgroups_statuses
    @jobgroups = []
    @jobgroups << "all"
    @jobgroups += @jobgroups_statuses.keys

    #Map jobs per jobgroup globally
    @jobgroup_job_count = {}
    #Add record for total number manually
    jobs_count = Job.all.count
    @jobgroup_job_count["all"] = jobs_count
    @jobgroups_statuses.each do |jobgroup,status_ids|
      jobs_count = Job.where(:status_id => status_ids).count
      @jobgroup_job_count[jobgroup] = jobs_count
    end

    @projects_jobgroups = {}
    #Map jobs per jobgroup per project
    Project.where(:deleted_at => nil).order("id ASC").each do |p|
      projectMap = {}
      #Add record for total number manually
      jobs_count = Job.where(:project_id => p.id).count
      projectMap["all"] = jobs_count
      @jobgroups_statuses.each do |jobgroup,status_ids|
        jobs_count = Job.where(:status_id => status_ids).where(:project_id => p.id).count
        projectMap[jobgroup] = jobs_count
      end
      @projects_jobgroups[p.name] = projectMap
    end

  end

  private
  #Returns a hash containing each jobgroups name and an array of status ids
  def get_jobgroups_statuses
    jobgroups_statuses = {}
    DigFlow::Application.config.project_jobgroups.each do |x|
      statuses = Array.new
      status_ids = Array.new
      if(!x.empty?)
        statuses = x[:statuses]
        if !statuses.blank?
          statuses.each do |y|
            status_ids << Status.find_by_name(y).id
          end
        end
      else
      end
      jobgroups_statuses[x[:name]] = status_ids
    end
    jobgroups_statuses
  end

end
