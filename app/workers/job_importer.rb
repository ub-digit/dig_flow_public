class JobImporter
  class ImportException < Exception
  end
  
  @queue = :job_import_queue
  def self.perform(import_id, job_data)
    job_metadata = job_data["metadata"] #Saves JSon data
    job_import_rownr = job_data["import_rownr"] #Saves JSon data
    #Deletes data to be able to create new job from job_data
    job_data.delete("metadata") 
    job_data.delete("id")
    job_data.delete("created_at")
    job_data.delete("updated_at")
    job_data.delete("import_rownr")

    dummy_job = Job.new(job_data) #Creates new empty job
    #dummy_job.metadata = job_metadata
    
    begin
      @job = dummy_job.source_object.create_job(dummy_job.user_id, dummy_job.project_id, dummy_job.catalog_id)
      @job.metadata ||= [] #Should be moved to source_object.create_job
      @job.metadata += job_metadata #Should be moved to source_object.create_job
      @job.name = dummy_job.name #Should be moved to source_object.create_job
      @job.object_info = dummy_job.object_info #Should be moved to source_object.create_job
      @job.priority = dummy_job.priority #Should be moved to source_object.create_job
      @job.guessed_page_count = dummy_job.guessed_page_count #Should be moved to source_object.create_job
      @job.comment = dummy_job.comment #Should be moved to source_object.create_job
      @job.import_rownr = job_import_rownr

      store_import_data(import_id, @job, "success")
    rescue SourceBase::SourceFetchFailed
      dummy_job.failed = true
      store_import_data(import_id, dummy_job, "fail")
      raise ImportException
    rescue
      dummy_job.failed = true
      store_import_data(import_id, dummy_job, "fail")
      raise ImportException
    end
  end

  def self.store_import_data(import_id, job, status = "success")
    store = Redis.new
    unique_import_job_id = store.incr("dflow:import:job:id")
    store.setex("dflow:import:#{import_id}:#{unique_import_job_id}:data", 2.days, job.to_yaml)
    store.setex("dflow:import:#{import_id}:#{unique_import_job_id}:status", 2.days, status)
    if(status == "fail")
      store.setex("dflow:import:#{import_id}:failed", 2.days, "true")
    end
  end
end
