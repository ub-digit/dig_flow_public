require 'job_importer'
require './app/assets/sources/libris.rb'
require './app/assets/sources/document.rb'
require './app/assets/sources/letter.rb'

class JobsController < ApplicationController

  before_filter :login_if_not_logged_in, :except => [:index, :show]
  layout false, :only => [:print]

  def index
    params[:view] = params[:view] || cookies[:view] || DigFlow::Application.config.filter_views.first[:name]
    params[:reverse] = (params[:reverse] == "true" ? true : false)
    params[:quarantined] = (params[:quarantined] == "true" ? true : params[:quarantined] == "false" ? false : nil)
    if params[:search].blank?
      @jobs = Job.where(:deleted_at => nil)
    else
      @jobs = Job.search(params[:search]).where(:deleted_at => nil)
    end
    @creators = User.creators
    @owners = User.owners
    @statuses = Status.where("selection_order is not null").order(:selection_order).map {|x| [t("statuses."+x.name) + " (" + x.id.to_s + ")", x.id]}
    @projects = Project.where(:deleted_at => nil).order(:name)
    
    
    @jobs = @jobs.where(:status_id => params[:status_id]) unless params[:status_id].blank?
    @jobs = @jobs.where(:user_id => params[:user_id]) unless params[:user_id].blank?
    @jobs = @jobs.where(:project_id => params[:project_id]) unless params[:project_id].blank?
    @jobs = @jobs.where(:quarantined => params[:quarantined]) unless params[:quarantined].blank?
    
    # Filter parameters for owner, created_by, status, project
    @jobs = @jobs.where(:user_id => params[:f_o]) unless params[:f_o].blank?
    @jobs = @jobs.where(:created_by => params[:f_c]) unless params[:f_c].blank?
    @jobs = @jobs.where(:status_id => params[:f_s]) unless params[:f_s].blank?
    @jobs = @jobs.where(:project_id => params[:f_p]) unless params[:f_p].blank?
    
    #Filter parameters for view
    @view = DigFlow::Application.config.filter_views.select {|view| view[:name] == params[:view]}[0]
    @view[:filters].each do |key,filter|
      @jobs = @jobs.where(key => filter)
    end
    
    if params[:sort_column].blank?
      @jobs = @jobs.order("id DESC")
    else
      @jobs = @jobs.order("#{params[:sort_column]} #{params[:reverse] ? "DESC" : "ASC"}")
    end
    @per_page = params[:per_page] || cookies[:per_page] || 25 # get hits per page value from selection or cookie
    cookies.permanent[:per_page] = @per_page
    @jobs = @jobs.paginate(:page => params[:page], :per_page => @per_page)
    
    cookies.permanent[:view] = @view[:name]
  end

  def show
    @job = Job.find(params[:id])


    @projects = Project.where(:deleted_at => nil).order(:name).map { |x| [x.name, x.id] }
    @creator= User.find(@job.created_by)
    @xml = Nokogiri::XML(@job.xml)
    @xml.remove_namespaces!
    @xslt = @job.source_object.xslt
    @activities = Activity.where(:entity_type => @job.class.to_s).where(:entity_id => @job.id).order(:created_at)
    @statuses = Status.where("selection_order is not null").order(:selection_order).map {|x| [t("statuses."+x.name) + " (" + x.id.to_s + ")", x.id]}
    @copyrights = copyrights_list @job.project

    #metadata serials
    @chron_1_key=""
    @chron_1_value=""
    @chron_2_key=""
    @chron_2_value=""
    @chron_3_key=""
    @chron_3_value=""
    @ordinal_1_key=""
    @ordinal_1_value=""
    @ordinal_2_key=""
    @ordinal_2_value=""
    @ordinal_3_key=""
    @ordinal_3_value=""

   @job.job_metadata.each_with_index do |p,index| [:key, :value]  
    if p.key == "chron_1_key" 
      @chron_1_key=p.value 
    end 
    if p.key == "chron_1_value" 
      @chron_1_value=p.value 
   end 
    if p.key == "chron_2_key"
      @chron_2_key=p.value 
     end 
     if p.key == "chron_2_value" 
      @chron_2_value=p.value 
     end 
     if p.key == "chron_3_key" 
      @chron_3_key=p.value 
     end 
     if p.key == "chron_3_value" 
      @chron_3_value=p.value 
     end 
     if p.key == "ordinal_1_key" 
      @ordinal_1_key=p.value 
     end 
     if p.key == "ordinal_1_value" 
      @ordinal_1_value=p.value 
     end 
     if p.key == "ordinal_2_key"
      @ordinal_2_key=p.value 
     end 
     if p.key == "ordinal_2_value" 
      @ordinal_2_value=p.value 
     end 
     if p.key == "ordinal_3_key" 
      @ordinal_3_key=p.value 
     end 
    if p.key == "ordinal_3_value" 
      @ordinal_3_value=p.value 
     end 
   end


    #job_switcher helpers
    @firstJob = Job.where(:project_id => @job.project.id).order("id DESC").first
    @lastJob = Job.where(:project_id => @job.project.id).order("id DESC").last
    @nextJob = Job.where("id < " + @job.id.to_s).where(:project_id => @job.project.id).order("id DESC").first
    @previousJob = Job.where("id > " + @job.id.to_s).where(:project_id => @job.project.id).order("id ASC").first

    respond_to do |format|
      format.html
      format.xml { render :xml => @job.to_xml(:include => :job_metadata) }
      format.json { render :xml => @job.to_json(:include => :job_metadata) }
      format.pdf { send_file @job.get_pdf, :filename => @job.mets_data[:id]+".pdf", :type => "text/pdf" }
    end
    
  end

  def print
    @job = Job.find(params[:id])
    respond_to do |format|
      format.html
      format.xml { render :xml => @job.to_xml(:include => :job_metadata) }
      format.json { render :xml => @job.to_json(:include => :job_metadata) }
    end
  end
  def new
    @source = Source.find(params[:job][:source_id])

    dummy_job = Job.new(params[:job])
    if dummy_job.catalog_id
      begin
        @job = dummy_job.source_object.create_job(dummy_job.user_id, dummy_job.project_id, dummy_job.catalog_id)
        @metadata = @job.metadata.group_by { |x| x[0] }
      rescue SourceBase::SourceFetchFailed
        params[:error] = "fetch_failed"
        redirect_to catalog_request_jobs_path(params)
        return
      end
      @data_fetched = true
    end
    @copyrights = copyrights_list @job.project
    @new_job = true
    cookies.permanent["#{@job.project.id}_defaultsource"] = @source.id
    @jobs_with_same_catalog_id = Job.where(:catalog_id => @job.catalog_id).where(:source_id => @job.source_id)
  end

  def create
    params[:job][:copyright] = nil unless ["1","2"].include? params[:job][:copyright] #Resets value to nil, fix because the radio input defaults value to "0" if nil
    params[:job].delete_if { |k,v| params[:job][k].blank? }
    params[:job][:metadata] = YAML.load(params[:job][:metadata])
    @job = Job.new(params[:job])
#    @job.fetch_librisdata_marc
    if @job.save
      @job.metadata.each do |metadata|
        @job.job_metadata.create(:key => metadata[0], :value => metadata[1], :metadata_type => metadata[2])
      end
#      @job.job_metadata.create(:key => "type_of_record", :value => @job.metadata.last[1], :metadata_type => "string")
      if @job.type_of_record == 'as'
        @chron_keys=params[:job_metadata_chron_key]
        @chron_values=params[:job_metadata_chron_value]
        @ord_keys=params[:job_metadata_ord_key]
        @ord_values=params[:job_metadata_ord_value]

        @ord_keys.each_with_index do |v,index|
          @key_order=index +1 
          if !(@ord_keys[index].blank? || @ord_values[index].blank?) 
            @job.job_metadata.create(:key => "ordinal_#{@key_order}_key", :value => v, :metadata_type => 'string')
            @job.job_metadata.create(:key => "ordinal_#{@key_order}_value", :value => @ord_values[index], :metadata_type => 'string')
          end
        end

        @chron_keys.each_with_index do |v,index|
          @key_order=index +1 
          if !(@chron_keys[index].blank? || @chron_values[index].blank?) 
            @job.job_metadata.create(:key => "chron_#{@key_order}_key", :value => v, :metadata_type => 'string')
            @job.job_metadata.create(:key => "chron_#{@key_order}_value", :value => @chron_values[index], :metadata_type => 'string')
          end
        end
      end
      event = Event.find_by_name("change_status")
      event.run_event(@job, Status.find_by_name("create_end").id)
      event.run_event(@job, Status.find_by_name("waiting_for_digitizing_begin").id)
      redirect_to catalog_request_jobs_path(:job => {:project_id => @job.project.id, :user_id => @current_user.id}, :newest_job_id => @job.id) #Redirects to creating a another job for the same project
      #      redirect_to project_path(@job.project) # redirects to project page
      return
    end
    @copyrights = copyrights_list @job.project
    render :action => 'new'
  end

  def edit
    @job = Job.find(params[:id])
    @data_fetched = true if !@job.catalog_id.blank?
    @copyrights = copyrights_list @job.project
  end

  def update
    @job = Job.find(params[:id])
    params[:job].delete_if { |k,v| params[:job][k].blank? }
    params[:job][:name] ||= nil
    params[:job][:object_info] ||= nil
    params[:job][:comment] ||= nil
   
    if params[:job_metadata_update]
      if @job.type_of_record == 'as'
        @job.job_metadata.each do |x|
        x.update_attribute(:deleted_at,Time.now)
      end

        @job.job_metadata.create(:key => "type_of_record", :value => 'as', :metadata_type => "string")
        @chron_keys=params[:job_metadata_chron_key]
        @chron_values=params[:job_metadata_chron_value]
        @ord_keys=params[:job_metadata_ord_key]
        @ord_values=params[:job_metadata_ord_value]

        @ord_keys.each_with_index do |v,index|
          @key_order=index +1 
          if !(@ord_keys[index].blank? || @ord_values[index].blank?) 
            @job.job_metadata.create(:key => "ordinal_#{@key_order}_key", :value => v, :metadata_type => 'string')
            @job.job_metadata.create(:key => "ordinal_#{@key_order}_value", :value => @ord_values[index], :metadata_type => 'string')
          end
        end

        @chron_keys.each_with_index do |v,index|
          @key_order=index +1 
          if !(@chron_keys[index].blank? || @chron_values[index].blank?) 
            @job.job_metadata.create(:key => "chron_#{@key_order}_key", :value => v, :metadata_type => 'string')
            @job.job_metadata.create(:key => "chron_#{@key_order}_value", :value => @chron_values[index], :metadata_type => 'string')
          end
        end
      end
    end

    
    if @job.update_attributes(params[:job])
      redirect_to job_path(@job)
      return
    end

  
    @copyrights = copyrights_list @job.project
    render :action => 'edit'
  end

  def update_priority
    @job = Job.find(params[:id])
    if @job
      @job.update_attribute(:priority, params[:priority])
      redirect_to job_path(@job)
    else
      redirect_to projects_path
    end
  end

  def delete
    @job = Job.find(params[:id])
    @job.update_attribute( :deleted_at, Time.now)
    redirect_to project_path(@job.project)
  end

  def catalog_request
    @project = Project.find(params[:job][:project_id])
    @newest_job = params[:newest_job_id] != nil ? Job.find(params[:newest_job_id]) : nil
    @sources = Source.all
  end

  def import
    @project = Project.find(params[:job][:project_id])
    @sources = Source.all
  end

  def batch_fetch
    @file = params[:job][:import_file]
    @project = Project.find(params[:job][:project_id])
    @filedata = @file.read.force_encoding("utf-8").split(/\r?\n/).map { |x| x.split(/\t/) }
    @import_id = generate_import_id
    @column_names = @filedata[0]
    if @column_names[0][0] == "\ufeff"
      @column_names[0] = @column_names[0][1..-1]
    end
    @filedata = @filedata[3..-1]
    @jobs = []
    job_count = 0
    @filedata.each do |row|
      job_count += 1
      rowdata = Hash[@column_names.zip(row)]
      job = Job.new(:catalog_id => rowdata["catalog_id"],
        :status_id => Status.find_by_name("create_begin").id,
        :project_id => params[:job][:project_id],
        :name => rowdata["name"].blank? ? nil : rowdata["name"],
        :object_info => rowdata["note"].blank? ? nil : rowdata["note"],
        :comment => rowdata["comment"].blank? ? nil : rowdata["comment"],
        :guessed_page_count => rowdata["guessed_page_count"].blank? ? 0 : rowdata["guessed_page_count"],
        :priority => rowdata["prio"].blank? ? 0 : rowdata["prio"])
      
      job.import_rownr = job_count
      job.source_id = params[:job][:source_id]
      (@column_names-["catalog_id", "name", "prio", "note", nil, ""]).each do |metadata_key|
        job.metadata ||= []
        job.metadata << [metadata_key, rowdata[metadata_key], "string"]
      end
      
      Resque.enqueue(JobImporter, @import_id, job)
      redis.setex("dflow:import:#{@import_id}:count", 2.days, redis.get("dflow:import:#{@import_id}:count").to_i+1)
      redis.setex("dflow:import:#{@import_id}:column_names", 2.days, @column_names.to_yaml)
    end
    @copyrights = copyrights_list @project

    redirect_to batch_import_status_jobs_path(:import_id => @import_id, :project_id => @project.id, :source_id => params[:job][:source_id])
  end

  def batch_import_status
    Job.new
    @import_id = params[:import_id]
    @source = Source.find(params[:source_id])
    @import_failed = (redis.get("dflow:import:#{@import_id}:failed") == "true")
    @import_job_count = redis.get("dflow:import:#{@import_id}:count").to_i
    @import_processed_count = redis.keys("dflow:import:#{@import_id}:*:status").count.to_i
    @import_progress = (100*(@import_processed_count.to_f/@import_job_count)).to_i
    @column_names = YAML.load(redis.get("dflow:import:#{@import_id}:column_names"))
    @jobs_success = []
    @jobs_fail = []
    @project = Project.find(params[:project_id])
    @copyrights = copyrights_list @project
    redis.keys("dflow:import:#{@import_id}:*:status").each do |job_status_key|
      job_data_key = job_status_key.gsub(/:status$/, ":data")
      if redis.get(job_status_key) == "success"
        @jobs_success << YAML.load(redis.get(job_data_key))
      else
        @jobs_fail << YAML.load(redis.get(job_data_key))
      end
    end
  end

  def batch_import
    Job.new
    @project = Project.find(params[:job][:project_id])
#    @jobs = YAML.load(params[:job][:all_jobs])
    @import_id = params[:job][:import_id]
    @jobs = []
    redis.keys("dflow:import:#{@import_id}:*:status").each do |job_status_key|
      job_data_key = job_status_key.gsub(/:status$/, ":data")
      if redis.get(job_status_key) == "success"
        @jobs << YAML.load(redis.get(job_data_key))
      end
    end
    params[:job][:new_copyright] = nil unless ["1","2"].include? params[:job][:new_copyright] #Resets value to nil, fix because the radio input defaults value to "0" if nil
    copyright = params[:job][:new_copyright]
    status = @jobs.sort_by{|x| x.import_rownr}.map do |job|
      job.instance_variable_set("@new_record", true)
      job.copyright = copyright
      if job.save
        job.metadata.each do |metadatum|
          job.job_metadata.create(:key => metadatum[0], :value => metadatum[1], :metadata_type => metadatum[2])
        end
        current_job = Job.find_by_id(job.id)
        event = Event.find_by_name("change_status")
        event.run_event(current_job, Status.find_by_name("create_end").id)
        event.run_event(current_job, Status.find_by_name("waiting_for_digitizing_begin").id)
      end
    end
    #    flash[:notice] = @jobs.map(&:catalog_id).zip(status).first
    redirect_to project_path(@project)
  end

  def digitizing_begin
    @job = Job.find(params[:id])
    raise "Wrong status" if params[:force] != "true" && @job.status.name != "waiting_for_digitizing_begin"

    if @job.user_id != @current_user.id
      @event = Event.find_by_name("change_user")
      @event.run_event(@job, @current_user.id)
    end
    @event = Event.find_by_name("change_status")
    @event.run_event(@job, @job.status.end_status.id) if @job.status.end_status
    @event.run_event(@job, Status.find_by_name("digitizing_begin").id)
    redirect_to :action => 'show', :id => @job.id
  end

  def digitizing_end
    @job = Job.find(params[:id])
    if !@job.quarantined 
      if @job.mets_metadata_control #Run metadata control before digitize_end can be set. Control methoid quarantines job if necessary
        api_status_update("digitizing_begin", "waiting_for_post_processing_begin")
      end
    end
  end

  def post_processing_begin
    api_status_update("waiting_for_post_processing_begin", "post_processing_begin")
  end

  def post_processing_user_input_begin
    api_status_update("post_processing_begin", "post_processing_user_input_begin")
  end

  def post_processing_user_input_end
    api_status_update("post_processing_user_input_begin", "post_processing_user_input_end")
  end

  def post_processing_end
    api_status_update("post_processing_begin", "waiting_for_quality_control_begin")
  end

  def quality_control_begin
    @job = Job.find(params[:id])
    run_quality_control_begin(@job)
    redirect_to :action => 'show', :id => @job.id
  end

  def quarantine
    @job = Job.find(params[:id])
    note = params[:note].blank? ? nil : params[:note]
    raise "Note missing" if !note
    if @job.user_id != @current_user.id
      @event = Event.find_by_name("change_user")
      @event.run_event(@job, @current_user.id)
    end
    @event = Event.find_by_name("quarantine")
    @event.run_event(@job, 0, note)
    AlertMailer.quarantine_alert(@job,note,@current_user, "quarantined").deliver #Send alert email
    redirect_to :action => 'show', :id => @job.id
  end

  def unquarantine
    @job = Job.find(params[:id])
    note = params[:note].blank? ? nil : params[:note]
    if @job.user_id != @current_user.id
      @event = Event.find_by_name("change_user")
      @event.run_event(@job, @current_user.id)
    end
    @event = Event.find_by_name("unquarantine")
    @event.run_event(@job, 0, note)
    newstatus = DigFlow::Application.config.unquarantine_status_routes[@job.status.name] #Get status after quarantine from config
    AlertMailer.quarantine_alert(@job,note,@current_user, "unquarantined").deliver #Send alert email
    if newstatus != nil
      api_status_update(@job.status.name, newstatus) #If status after quarantine is set, change status
    else
      redirect_to :action => 'show', :id => @job.id
    end
  end
  
  #Resets the jobs status to 'waiting_for_digitize_begin', and renames storage folder (if any)
  def restart
    @job = Job.find(params[:id])
    note = params[:note].blank? ? nil : params[:note]
    raise "Note missing" if !note
    if @job.user_id != @current_user.id
      @event = Event.find_by_name("change_user")
      @event.run_event(@job, @current_user.id)
    end
    @job.restart
    AlertMailer.restart_alert(@job,note,@current_user).deliver #Send alert email
    event = Event.find_by_name("change_status")
    event.run_event(@job, Status.find_by_name("waiting_for_digitizing_begin").id, t("jobs.restart") + ": " + note)
    redirect_to :action => 'show', :id => @job.id
  end

  def batch_quality_control
    checked = params[:quality_control].select { |k,v| v == "1" }.keys
    checked.each do |job_id|
-      @job = Job.find(job_id)
      run_quality_control_begin(@job)
    end
    redirect_to :controller => "projects", :action => 'show', :id => params[:project_id]
  end

  def job_edit
    @jobedit = Job.find(params[:id])
    if params[:job]
      new_status = Status.find_by_id(params[:job][:new_status])
      if new_status
        api_status_update(@jobedit.status.name, new_status.name)
      else
        flash[:notice] = t("jobs.status_error")
      end
    else
      flash[:notice] = t("jobs.status_error")
    end
  end

  def job_move
    @jobmove = Job.find(params[:id])
    if !@jobmove
      redirect_to projects_path()
      return
    end
    if params[:job]
      new_project = Project.find_by_id(params[:job][:new_project])
      if new_project
        event = Event.find_by_name("change_project")
        event.run_event(@jobmove, new_project.id)
      else
        flash[:notice] = t("jobs.move_error")
      end
    else
      flash[:notice] = t("jobs.move_error")
    end
    redirect_to job_path(@jobmove)
  end
  
  def job_copyright
    job = Job.find_by_id(params[:id])
    if !job
      redirect_to projects_path()
      return
    end
    if params[:job]
      job.copyright = params[:job][:new_copyright]
      job.save
    else
      redirect_to projects_path()
    end
    
    redirect_to job_path(job)
  end

  private
  def api_status_update(from_status_name, to_status_name)
    @job = Job.find(params[:id])
    note = params[:note].blank? ? nil : params[:note]
    raise "Wrong status" if @job.status.name != from_status_name

    @event = Event.find_by_name("change_status")
    new_status = Status.find_by_name(to_status_name)
    if new_status.return_to_previous
      last_change = Activity.where(:entity_type => "Job", :entity_id => @job.id,
        :event_id => @event.id).order("created_at DESC").first.from_id.to_i
      @event.run_event(@job, new_status.id, note)
      @job.update_attribute(:status_id, last_change)
    else
      unless new_status.end_status && new_status.end_status.return_to_previous 
        @event.run_event(@job, @job.status.end_status.id, note) unless @job.status.end_status == nil #Added unless statement because of nil exceptions
        note = nil
      end
      @event.run_event(@job, new_status.id, note)
    end

    if @current_user.api_login != true
      redirect_to :action => 'show', :id => @job.id
    else
      render :text => "ok"
    end
  end

  def run_quality_control_begin(job)
    raise "Wrong status" if job.status.name != "waiting_for_quality_control_begin"

    if job.user_id != @current_user.id
      @event = Event.find_by_name("change_user")
      @event.run_event(job, @current_user.id)
    end
    @event = Event.find_by_name("change_status")
    @event.run_event(job, job.status.end_status.id)
    @event.run_event(job, Status.find_by_name("quality_control_begin").id)
    @event.run_event(job, Status.find_by_name("quality_control_end").id)
    @event.run_event(job, Status.find_by_name("waiting_for_mets_control_begin").id)
  end
  
  
  def copyrights_list(project)
    copyrights = DigFlow::Application.config.copyright.keys.map do |x|
      if !x
        if project.copyright
          [t("mets_data.copyright_status.default_from_project") + " (" + t("mets_data.copyright_status."+DigFlow::Application.config.copyright[project.copyright][:name]) + ")", x]
        else
          [t("mets_data.copyright_status.default_from_config") + " (" + t("mets_data.copyright_status."+DigFlow::Application.config.copyright[x][:name]) + ")", x]
        end
      else
        [t("mets_data.copyright_status."+DigFlow::Application.config.copyright[x][:name]), x]
      end
    end
  end

  def redis
    @redis || Redis.new
  end

  def generate_import_id
    redis.incr("dflow:import:id")
  end
  
end
