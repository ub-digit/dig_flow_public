# -*- coding: utf-8 -*-
require 'pathname'
require 'iconv'

class Job < ActiveRecord::Base
  default_scope where( :deleted_at => nil ) #Hides all deleted jobs from all queries, works as long as no deleted jobs needs to be visualized in dFlow
  attr_accessible :author, :barcode, :catalog_id, :created_by, :deleted_at, :deleted_by, :name, :project_id, :status_id, :title, :updated_by, :user_id, :xml, :mods, :quarantined, :priority, :object_info, :comment, :copyright, :page_count, :guessed_page_count, :source_id, :metadata, :search_title
  belongs_to :status
  belongs_to :user
  belongs_to :project
  belongs_to :source
  has_many :job_metadata
  before_save :generate_search_title
  before_validation :generate_source_id

  validates :status_id, :presence => true
  validates :user_id, :presence => true
  validates :project_id, :presence => true
  validates :title, :presence => true
  validates :catalog_id, :presence => true
  validates :barcode, :format => { :with => /\A(\S|\S.*\S)\Z/i }, :if => :barcode_present?
  validates :source_id, :presence => true
  validate :status_validity
  validate :user_validity
  validate :project_validity
  validate :xml_validity
  validate :mods_validity
  before_validation :project_user_if_user_missing, :on => :create
  attr_accessor :failed
  attr_accessor :metadata
  attr_accessor :new_status
  attr_accessor :new_project
  attr_accessor :new_copyright
  attr_accessor :import_rownr


  def column_data(key)
    case key
    when "title"
      return title
    when "author"
      return author
    when "id"
      return id
    when "user_id"
      return user.name
    when "status_id"
      return status.name
    when "catalog_id"
      return catalog_id
    when "project_id"
      return project.name
    else
      metadata = job_metadata.find_by_key(key)
      return metadata ? metadata.value : ""
    end
  end

  def self.search(searchterm)
    Job.where("(lower(title) LIKE ?) OR (lower(name) LIKE ? ) OR (lower(author) LIKE ?) OR (lower(search_title) LIKE ?) OR (id = ?) OR (catalog_id = ?)",
      "%#{searchterm.downcase}%",
      "%#{searchterm.downcase}%",
      "%#{searchterm.downcase}%",
      "%#{searchterm.downcase}%",
      searchterm[/^\d+$/] ? searchterm.to_i : nil,
      searchterm[/^\d+$/] ? searchterm.to_i : nil)
  end

  def is_prioritized?
    self.priority > 0
  end

  def source_object
    source || Source.find_by_classname("Libris")
  end

  #Renames any created folder with a restarted-prefix
  def restart
    short_path = Pathname.new(mets_data[:dflow_path]+"/"+id.to_s)
    long_path = Pathname.new(mets_data[:dflow_path]+"/"+mets_data[:id])
    restarted_path = Pathname.new(mets_data[:dflow_path]+"/"+mets_data[:restarted])
    if short_path.exist?
      restarted_path = auto_increment_path(mets_data[:dflow_path]+"/"+mets_data[:restarted]+id.to_s)
      short_path.rename(restarted_path.to_s)
    end
    if long_path.exist?
      restarted_path = auto_increment_path(mets_data[:dflow_path]+"/"+mets_data[:restarted]+mets_data[:id])
      long_path.rename(restarted_path.to_s)
    end
  end
  
  #Generic method to create incremented folder when exists i.e. "FolderName_1" "FolderName_2" etc
  def auto_increment_path(path_string)
    i = 1;
    path = Pathname.new(path_string)
    while path.exist?
      path = Pathname.new(path_string + "_" + i.to_s)
      i += 1
    end
    return path
  end

  def xml_valid?(xml)
    test=Nokogiri::XML(xml)
    test.errors.empty?
  end

  def mets_data
    {
      :id => sprintf("GUB%07d", id),
      :created_at => created_at.strftime("%FT%T"),
      :updated_at => updated_at.strftime("%FT%T"),
      :creator_sigel => DigFlow::Application.config.mets_head[:creator][:sigel],
      :creator_name => DigFlow::Application.config.mets_head[:creator][:name],
      :archivist_sigel => DigFlow::Application.config.mets_head[:archivist][:sigel],
      :archivist_name => DigFlow::Application.config.mets_head[:archivist][:name],
      :copyright_status => DigFlow::Application.config.copyright[copyright_value][:copyright_status],
      :publication_status => DigFlow::Application.config.copyright[copyright_value][:publication_status],
      :dflow_path => DigFlow::Application.config.base_scan_directory,
      :storage_path => DigFlow::Application.config.base_store_directory,
      :restarted => "_RESTARTED_"
    }
  end

  # Get the name of the directory where the mets files lives.
  # If no such directory is found, the job will end up in quarantine.
  def mets_job_directory(rename_and_quarantine = true)
    short_path = Pathname.new(mets_data[:dflow_path]+"/"+id.to_s)
    long_path = Pathname.new(mets_data[:dflow_path]+"/"+mets_data[:id])
    storage_path = Pathname.new(mets_data[:storage_path]+"/"+mets_data[:id])
    if [short_path, long_path, storage_path].select {|path| path.exist?}.count > 1
      set_quarantine(I18n.t("mets.errors.job_directory_exists_twice")) if rename_and_quarantine
      return nil
    end
    if [short_path, long_path, storage_path].select {|path| path.exist?}.count < 1
      set_quarantine(I18n.t("mets.errors.job_directory_missing")) if rename_and_quarantine
      return nil
    end
    if short_path.exist?
      if rename_and_quarantine
        short_path.rename(long_path.to_s)
      else
        return short_path
      end
    end
    if long_path.exist?
      return long_path
    end
    storage_path
  end

  def mets_pdf_file(rename = true)
    short_name = mets_job_directory(rename).to_s+"/pdf/"+id.to_s+".pdf"
    long_name = mets_job_directory(rename).to_s+"/pdf/"+mets_data[:id]+".pdf"
    if File.exist?(short_name)
      if rename
        Pathname.new(short_name).rename(long_name)
      else
        return short_name
      end
    end
    return long_name if File.exist?(long_name)
    nil
  end

  def mets_file_groups
    DigFlow::Application.config.mets_filegroups
  end

  def mets_files(file_group)
    if file_group[:single]
      return [{
          :full_path => mets_pdf_file,
          :number => mets_data[:id],
          :name => mets_data[:id]+"."+file_group[:extension]
        }]
    end
    Pathname.new(mets_job_directory.to_s+"/"+file_group[:name]).children.sort_by { |x| x.basename.to_s[/^(\d+)\./,1].to_i }.map do |child|
      next if !child.file?
      next if !child.basename.to_s[/^\d+\.#{file_group[:extension]}/]
      {
        :full_path => child.to_s,
        :name => child.basename.to_s,
        :number => child.basename.to_s[/^(\d+)\./,1]
      }
    end
  end

  def mets_page_count
    page_count = 0
    page_count_file = mets_job_directory.to_s+"/page_count/"+self.id.to_s+".txt"
    if File.exist?(page_count_file)
      page_count = File.read(page_count_file).to_i
    else
      set_quarantine(I18n.t("mets.errors.page_count_missing"))
      return nil
    end
    if page_count <= 0
      set_quarantine(I18n.t("mets.errors.page_count_to_low") + ": " + page_count.to_s)
      return nil
    end
    page_count
  end

  def mets_file_pagetype(file_num)
    padname = sprintf("%04d", file_num.to_i)
    filename = mets_job_directory(false).to_s+"/page_metadata/#{padname}.xml"
    if !File.exist?(filename)
      set_quarantine(I18n.t("mets.errors.page_metadata_missing")+": #{padname}.xml")
      return nil
    end
    File.open(filename, "rb") do |file|
      doc = Nokogiri::XML(Iconv.conv("UTF-8", "UTF-16", file.read))
      pos = doc.search("/ParametersPage/position")
      physical = pos.search("bookside").text
      logical = pos.search("pageContent").text
      group_name = doc.search("/ParametersPage/groupName").text
      return { :physical => physical.to_i, :logical => logical.to_i, :group_name => group_name.to_i }
    end
  end

  def mets_pagetypes(section, value)
    data = DigFlow::Application.config.mets_pagetypes
    return nil unless data[section]
    data[section][value.to_i] || "Undefined"
  end

  def mets_pagetype_map(page_num)
    pagetype = mets_file_pagetype(page_num)
    page_count = mets_page_count
    # Covers can only be first two and last two pages
    if mets_pagetypes(:physical, pagetype[:physical]) == "BookCover" && source_object.advanced_covers?
      # Cover structure:
      # Page 1 => FrontCoverOutside
      # Page 2 => FrontCoverInside
      # Page N-1 => BackCoverInside
      # Page N => BackCoverOutside
      # Any other page, error...
      case page_num
      when 1
        pagetype[:physical] = "FrontCoverOutside"
      when 2
        pagetype[:physical] = "FrontCoverInside"
      when page_count-1
        pagetype[:physical] = "BackCoverInside"
      when page_count
        pagetype[:physical] = "BackCoverOutside"
      else
        pagetype[:physical] = "Undefined"
      end
    else
      pagetype[:physical] = mets_pagetypes(:physical, pagetype[:physical])
    end
    pagetype[:logical] = mets_pagetypes(:logical, pagetype[:logical])
    if pagetype[:physical] == "Undefined"
      set_quarantine(I18n.t("mets.errors.page_not_defined")+": #{page_num}")
      return nil
    end
    puts "=========Innan validering============="
    puts source_object.classname
    if !source_object.validate_group_name(self, pagetype[:group_name])
      set_quarantine(I18n.t("mets.errors.group_name_not_found")+": #{page_num}: #{pagetype[:group_name]}")
      return nil
    end
    puts "========Efter validering============"
    return pagetype
  end

  def mets_control_check_files
    if !mets_job_directory
      return false
    end
    page_count = mets_page_count
    return false if !page_count
    mets_file_groups.each do |file_group|
      # Check if file group directory exists.
      if !Pathname.new(mets_job_directory.to_s+"/"+file_group[:name]).directory?
        set_quarantine(I18n.t("mets.errors.directory_missing")+": "+file_group[:name])
        return false
      end

      # Handle PDF differently
      if file_group[:single]
        if !mets_pdf_file
          set_quarantine(I18n.t("mets.errors.pdf_missing"))
          return false
        end
        if Pathname.new(mets_pdf_file).size == 0
          set_quarantine(I18n.t("mets.errors.pdf_empty"))
          return false
        end
        next
      end

      # PDFs don't get here

      # Check if file count is ok
      files = mets_files(file_group)
      if files.count != page_count
        set_quarantine(I18n.t("mets.errors.files_missing")+": "+file_group[:name])
        return false
      end

      # Check if all files in group exists in sequential order and are not empty
      page_count.times do |page_num|
        filename = sprintf("%04d", page_num+1)+"."+file_group[:extension]
        file = Pathname.new(mets_job_directory.to_s+"/"+file_group[:name]+"/"+filename)
        if !file.file?
          set_quarantine(I18n.t("mets.errors.file_missing")+": "+filename)
          return false
        end
        if file.size == 0
          set_quarantine(I18n.t("mets.errors.file_empty")+": "+filename)
          return false
        end
        if !mets_pagetype_map(page_num+1)
          return false
        end
      end
    end
    true
  end

  #Method seperated from the original file control, only focuses om metadat for an early check
  def mets_metadata_control
    begin
      source_object.refetch_xml(self)
      group_name_list = []
      page_count = Dir[mets_job_directory(false).to_s + "/page_metadata/**/*"].length-1
      page_count.times do |page|
        page_num = page+1
        pagetype = mets_file_pagetype(page_num)
        # Covers can only be first two and last two pages
        if mets_pagetypes(:physical, pagetype[:physical]) == "BookCover" && source_object.advanced_covers?
          # Cover structure:
          # Page 1 => FrontCoverOutside
          # Page 2 => FrontCoverInside
          # Page N-1 => BackCoverInside
          # Page N => BackCoverOutside
          # Any other page, error...
          case page_num
          when 1
            pagetype[:physical] = "FrontCoverOutside"
          when 2
            pagetype[:physical] = "FrontCoverInside"
          when page_count-1
            pagetype[:physical] = "BackCoverInside"
          when page_count
            pagetype[:physical] = "BackCoverOutside"
          else
            pagetype[:physical] = "Undefined"
          end
        else
          pagetype[:physical] = mets_pagetypes(:physical, pagetype[:physical])
        end
        pagetype[:logical] = mets_pagetypes(:logical, pagetype[:logical])
        if pagetype[:physical] == "Undefined"
          set_quarantine(I18n.t("mets.errors.page_not_defined")+": #{page_num}")
          return nil
        end
        if !source_object.validate_group_name(self, pagetype[:group_name])
          set_quarantine(I18n.t("mets.errors.group_name_not_found")+": #{page_num}: #{pagetype[:group_name]}")
          return nil
        end
        group_name_list << pagetype[:group_name]
      end
      source_object.clean_xml_groups(self, group_name_list)
      #source_object.schema_validation(self) #Commented by Lennarts request as this does not validate, xsd file seems faulty.
      if source_object.copyright_from_source?
        self.update_attribute(:copyright, source_object.copyright_id_from_source(self))
      end
      true
    ensure
      FileUtils.rm_r([mets_job_directory(false).to_s + "/page_metadata"]) unless !Pathname.new(mets_job_directory(false).to_s + "/page_metadata").exist? #Deletes uploaded page_metadata after checked if it exists
    end
  end

  def mets_checksum(file_name)
    checksum = nil
    File.open(file_name, "rb") do |file|
      checksum = Digest::SHA512.hexdigest(file.read)
    end
    checksum
  end

  def mets_pages
    page_count = mets_page_count
    (1..page_count).map do |page_num|
      {
        :num => page_num,
        :types => mets_pagetype_map(page_num)
      }
    end
  end

  def mets_head
    %Q{<mets:metsHdr ID="#{mets_data[:id]}"
                     CREATEDATE="#{mets_data[:created_at]}" LASTMODDATE="#{mets_data[:updated_at]}"
                     RECORDSTATUS="complete">
        <mets:agent ROLE="CREATOR" TYPE="ORGANIZATION" ID="#{mets_data[:creator_sigel]}">
         <mets:name>#{mets_data[:creator_name]}</mets:name>
        </mets:agent>
        <mets:agent ROLE="ARCHIVIST" TYPE="ORGANIZATION" ID="#{mets_data[:archivist_sigel]}">
         <mets:name>#{mets_data[:archivist_name]}</mets:name>
        </mets:agent>
       </mets:metsHdr>}
  end

  def mets_bibliographic
    %Q(<mets:dmdSec ID="dmdSec1" CREATED="#{mets_data[:created_at]}">
        <mets:mdWrap MDTYPE="#{source_object.xml_type(self)}">
         <mets:xmlData>
          #{source_object.xml_data(self)}
         </mets:xmlData>
        </mets:mdWrap>
       </mets:dmdSec>)
  end

  def mets_extra_dmdsecs
    source_object.mets_extra_dmdsecs(self, mets_data[:created_at])
  end

  def mets_administrative
    %Q(<mets:amdSec ID="amdSec1" >
        <mets:rightsMD ID="rightsDM1">
         <mets:mdWrap MDTYPE="OTHER">
          <mets:xmlData>
           <copyright copyright.status="#{mets_data[:copyright_status]}" publication.status="#{mets_data[:publication_status]}" xsi:noNamespaceSchemaLocation="http://www.cdlib.org/groups/rmg/docs/copyrightMD.xsd"/>
          </mets:xmlData>
         </mets:mdWrap>
        </mets:rightsMD>
       </mets:amdSec>)
  end

  def mets_file_section
    file_group_data = mets_file_groups.map do |file_group|
      "<mets:fileGrp USE=\"#{file_group[:name]}\">"+
        mets_files(file_group).map do |file|
        "<mets:file ID=\"#{file_group[:name]}#{file[:number]}\" MIMETYPE=\"#{file_group[:mimetype]}\" CHECKSUMTYPE=\"SHA-512\" CHECKSUM=\"#{mets_checksum(file[:full_path])}\">"+
          "  <mets:FLocat LOCTYPE=\"URL\" xlink:href=\"#{file_group[:name]}/#{file[:name]}\" />"+
          "</mets:file>"
      end.join("")+
        "</mets:fileGrp>"
    end
    %Q(<mets:fileSec ID="fileSec1">#{file_group_data.join("")}</mets:fileSec>)
  end

  def mets_structure(section)
    struct_type = case section
    when :physical
      "Physical"
    when :logical
      "Logical"
    end
    struct_id_prefix = case section
    when :physical
      "physical_"
    when :logical
      "logical_"
    end
    structure_data = mets_pages.map do |page|
      dmdid = ""
      if section == :logical && !page[:types][:group_name].blank?
        dmdid = source_object.mets_dmdid_attribute(self, page[:types][:group_name])
      end
      base = "<mets:div TYPE=\"#{page[:types][section]}\" ID=\"#{struct_id_prefix}divpage#{page[:num]}\" ORDER=\"#{page[:num]}\"#{dmdid}>"+
        mets_file_groups.map do |file_group|
        next '' if file_group[:single]
        "<mets:fptr FILEID=\"#{file_group[:name]}#{sprintf("%04d", page[:num])}\"/>"
      end.join("")+
        "</mets:div>"
    end.join("")
    %Q(<mets:structMap TYPE="#{struct_type}"><mets:div TYPE="#{I18n.t("mets.structure."+type_of_record)}">#{structure_data}</mets:div></mets:structMap>)
  end

  def mets_root(xml)
    %Q(<mets:mets xmlns:mets="http://www.loc.gov/METS/" xmlns:rights="http://www.loc.gov/rights/"
                  xmlns:xlink="http://www.w3.org/1999/xlink" xmlns:lc="http://www.loc.gov/mets/profiles"
                  xmlns:bib="http://www.loc.gov/mets/profiles/bibRecord" xmlns:mods="http://www.loc.gov/mods/v3"
                  xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" OBJID="loc.afc.afc9999005.1153"
                  xsi:schemaLocation="http://www.loc.gov/METS/ http://www.loc.gov/standards/mets/mets.xsd http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-2.xsd">#{xml}</mets:mets>)
  end

  def mets_xml
    xml = mets_head
    xml += mets_extra_dmdsecs
    xml += mets_bibliographic
    xml += mets_administrative
    xml += mets_file_section
    xml += mets_structure(:physical)
    xml += mets_structure(:logical)
    Nokogiri::XML(mets_root(xml), &:noblanks).to_xml(encoding:'utf-8')
  end

  def mets_control
    if status.name != "waiting_for_mets_control_begin"
      # Error! Change to better stuff
      raise WrongStatus
    end
    event = Event.find_by_name("change_status")
    event.run_event(self, Status.find_by_name("waiting_for_mets_control_end").id)
    event.run_event(self, Status.find_by_name("mets_control_begin").id)
    source_object.refetch_xml(self) #Refetching XML-data, including group names
    if mets_control_check_files
      event.run_event(self, Status.find_by_name("mets_control_end").id)
      return true
    end
    return false
  end

  def mets_produce
    if status.name != "mets_control_end"
      # Error! Change to better stuff
      raise WrongStatus
    end
    event = Event.find_by_name("change_status")
    event.run_event(self, Status.find_by_name("mets_production_begin").id)
    xml = mets_xml
    if xml_valid?(xml)
      begin
        File.open(mets_job_directory.to_s+"/"+mets_data[:id]+"_mets.xml", "w:utf-8") do |file|
          file.write(xml)
        end
      rescue
        set_quarantine(I18n.t("mets.errors.unable_to_write_file")+": #{mets_data[:id]}_mets.xml")
        return false
      end
      return false if !mets_create_zip
      event.run_event(self, Status.find_by_name("mets_production_end").id)
      event.run_event(self, Status.find_by_name("done").id)
      return false if !mets_move_folder
    else
      File.open("/tmp/debug.xml","w") { |f| f.write(xml) }
      set_quarantine(I18n.t("mets.errors.mets_xml_invalid"))
      return false
    end
    true
  end

  #Creates a zip file in /metadata/ folder containting the job's page_metadata and page_count
  def mets_create_zip
    if false && status.name != "mets_control_begin"
      # Error! Change to better stuff
      raise WrongStatus
    end

    old_pwd = FileUtils.pwd
    begin
      FileUtils.chdir(mets_job_directory.to_s)
      IO.popen(["zip", "-r", mets_data[:dflow_path] + "/metadata/" + "#{mets_data[:id]}.zip", "page_metadata", "page_count"]) { |f| f.read } #Creates zip file
      FileUtils.chmod(0644, mets_data[:dflow_path] + "/metadata/" + "#{mets_data[:id]}.zip")
      FileUtils.rm_r([mets_job_directory.to_s + "/page_metadata", mets_job_directory.to_s + "/page_count"]) #Deletes zipped folders from archive folder
    rescue
      set_quarantine(I18n.t("mets.errors.zip_creation_failed"))
      FileUtils.chdir(old_pwd)
      return false
    end
    FileUtils.chdir(old_pwd)
    return true
  end

  #Moves METS-folder to storage_path specified in config-file
  def mets_move_folder
    if false && status.name != "done"
      # Error! Change to better stuff
      raise WrongStatus
    end
    begin
      FileUtils.chmod_R("g-w", mets_job_directory.to_s)
      FileUtils.chown_R("root", nil, mets_job_directory.to_s)
      FileUtils.mv(mets_job_directory.to_s, mets_data[:storage_path])
    rescue
      set_quarantine(I18n.t("mets.errors.job_move_failed"))
      return false
    end
    return true
  end

  def mets_production_running?
    return false if quarantined?
    return true if [
      "waiting_for_mets_control_end", "mets_control_begin", "mets_control_end",
      "mets_production_begin", "mets_production_end"
    ].include?(status.name)
    false
  end

  def self.any_mets_production_running?
    Job.includes(:status).all.each do |job|
      return true if job.mets_production_running?
    end
    false
  end

  def self.find_job_waiting_for_mets
    return nil if any_mets_production_running?
    Job.where(:quarantined => false).where(:status_id => Status.find_by_name("waiting_for_mets_control_begin").id).first
  end

  def mets_valid?
    xml_valid?(mets_xml)
  end

  def xml_validity
    errors.add(:base, "Marc must be valid xml") unless xml_valid?(xml)
  end

  def mods_validity
    errors.add(:base, "Mods must be valid xml") unless xml_valid?(mods)
  end

  def barcode_present?
    !barcode.nil?
  end

  def created_by_present?
    !created_by.nil?
  end

  def status_validity
    errors.add(:base, "Status must be valid") unless Status.find_by_id(status_id)
  end

  def user_validity
    return if !user_id
    test_user = User.find_by_id(user_id)
    errors.add(:base, "User must be valid") unless test_user
    errors.add(:base, "User must be operator or admin") if test_user && !["operator", "admin"].include?(test_user.role.name)
  end


  def project_validity
    errors.add(:base, "Project must be valid") unless Project.find_by_id(project_id)
  end

  def project_user_if_user_missing
    self.user_id=project.user_id if !self.user_id
    self.created_by=self.user_id
  end

  def note
    note_md = job_metadata.where(:key => "note")
    return nil if note_md.blank?
    note_md.first.value
  end

  def type_of_record
    type_md = job_metadata.where(:key => "type_of_record")
    return "am" if type_md.blank? # Default to am
    type_md.first.value
  end

  def display_title
    title_trunc = title.truncate(DigFlow::Application.config.text[:truncate], separator: ' ')
    display = name || title_trunc
    if !ordinals.blank?
      display += " (#{ordinals})"
    else
      if !name.blank? && !title.blank?
        display += " (#{title_trunc})"
      end
    end
    display
  end

  def ordinals_and_chronologicals
    pt = ''
    if !ordinals.blank?
      pt += "(#{ordinals})"

      if !chronologicals.blank?
        pt += " (#{chronologicals})"
      end
    elsif !chronologicals.blank?
      pt += "(#{chronologicals})"
    end
    pt
  end



  def ordinals(return_raw = false)
    ordinal_metadata = Hash[job_metadata
      .where(:key => [1,2,3]
        .map{|x| ["ordinal_#{x}_key", "ordinal_#{x}_value"]}.flatten)
      .map {|x| [x.key, x.value]}]
    ordinal_data = []
    ordinal_data << ordinal_num(1, ordinal_metadata) if ordinal_num(1, ordinal_metadata)
    ordinal_data << ordinal_num(2, ordinal_metadata) if ordinal_num(2, ordinal_metadata)
    ordinal_data << ordinal_num(3, ordinal_metadata) if ordinal_num(3, ordinal_metadata)
    return ordinal_data if return_raw
    ordinal_data.map { |x| x.join(" ") }.join(", ")
  end

  def ordinal_num(num, ordinal_metadata)
    key = ordinal_metadata["ordinal_#{num}_key"]
    value = ordinal_metadata["ordinal_#{num}_value"]
    return nil if key.blank? || value.blank?
    [key, value]
  end

  def chronologicals(return_raw = false)
    chronological_metadata = Hash[job_metadata
      .where(:key => [1,2,3]
        .map{|x| ["chron_#{x}_key", "chron_#{x}_value"]}.flatten)
      .map {|x| [x.key, x.value]}]
    chronological_data = []
    chronological_data << chronological_num(1, chronological_metadata) if chronological_num(1, chronological_metadata)
    chronological_data << chronological_num(2, chronological_metadata) if chronological_num(2, chronological_metadata)
    chronological_data << chronological_num(3, chronological_metadata) if chronological_num(3, chronological_metadata)
    return chronological_data if return_raw
    chronological_data.map { |x| x.join(" ") }.join(", ")
  end

  def chronological_num(num, chronological_metadata)
    key = chronological_metadata["chron_#{num}_key"]
    value = chronological_metadata["chron_#{num}_value"]
    return nil if key.blank? || value.blank?
    [key, value]
  end

  def has_pdf?
    !!mets_pdf_file(false)
  end

  def get_pdf
    return nil unless has_pdf?
    File.open(mets_pdf_file(false), "rb")
  end

  def has_digitizing_begin?
    status.name == "waiting_for_digitizing_begin"
  end

  def waiting_for_quality_control?
    status.name == "waiting_for_quality_control_begin"
  end

  def is_done?
    status.name == "done"
  end

  def set_quarantine(note)
    event = Event.find_by_name("quarantine")
    event.run_event(self, 0, note)
    AlertMailer.quarantine_alert(self,note,nil, "quarantined").deliver #Send an alert email when system puts job in quarantine
  end

  def quarantine
    Quarantine.new
  end

  def unquarantine
    Unquarantine.new
  end

  def quarantine_id=(value)
    self.quarantined = true
  end

  def unquarantine_id=(value)
    self.quarantined = false
  end

  def as_json(opts)
    super.merge({
                  :metadata => metadata,
                  :import_rownr => import_rownr
                })
  end

  # encode_with and init_with necessary for to_yaml to include @metadata
  def encode_with(coder)
    super
    coder['metadata'] = metadata
    coder['import_rownr'] = import_rownr
  end

  def init_with(coder)
    super
    @metadata = coder['metadata']
    self.import_rownr = coder['import_rownr']
    self
  end

  def copyright_value
    copyright || self.project.copyright_value
  end

  #returns the job's progress as a percentage integer, based on the current status compared to total amount of statuses
  def progress
    cnt_statuses = Status.where("selection_order is not null").count;
    cnt_status_progress = Status.where("selection_order is not null").where("selection_order <= " + self.status.selection_order.to_s).count
    return 100*(cnt_status_progress.to_f/cnt_statuses.to_f)
  end

  def generate_search_title
    self.search_title = source_object.search_title(self)
  end

  def generate_source_id
    self.source_id = source_object.id unless self.source_id
  end
end
