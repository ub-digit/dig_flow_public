
class User < ActiveRecord::Base
  attr_accessible :email, :name, :password, :role_id, :username, :password_confirm, :mailalerts, :deleted_at
  belongs_to :role
  has_many :projects
  has_many :jobs
  validates :email, :format => { :with => /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\Z/i }, :if => :email_present?
  validates :username, :presence => true
  validates :username, :uniqueness => true
  validates :name, :presence => true
  validates :role_id, :presence => true
  validate :role_validity
  validate :password_validity
  attr_accessor :password_confirm
  attr_reader :api_login

  def encrypt_password(in_password, in_salt = nil)
    if in_salt.nil?
      in_salt = Digest::MD5.hexdigest(Time.now.to_f.to_s)[0..7]
    end
    "$1$#{in_salt}$#{Digest::MD5.hexdigest(Digest::MD5.hexdigest(in_password)+in_salt)}"
  end

  def salt
    return nil if !password
    password.split("$")[2]
  end

  def self.admins
    User.where(:role_id => Role.find_by_name("admin"))
  end

  def self.real
    User.where("role_id != ?", Role.find_by_name("guest").id).where(:deleted_at => nil)
  end
  
  def self.creators
    User.find_by_sql(%Q{select id, name from users where id in (select created_by from jobs where created_by is not null and deleted_at is null group by created_by) order by name asc;})
  end
  
  def self.owners
    User.find_by_sql(%Q{select id, name from users where id in (select user_id from jobs where user_id is not null and deleted_at is null group by user_id) order by name asc;})
  end

  def self.deleted
    User.where("role_id != ?", Role.find_by_name("guest").id).where("deleted_at IS NOT NULL")
  end

  def email_present?
    !email.nil?
  end

  def role_validity
    errors.add(:role_id, "Role must be valid") unless Role.find_by_id(role_id)
  end

  def password_validity
    guest_role = Role.find_by_name("guest")
    if role_id == guest_role.id
      errors.add(:password, "Guest password must not exist") unless password.nil?
    else
      errors.add(:password, "Must have password") if password.blank?
    end
  end

  def authenticate(in_password)
    encrypt_password(in_password, salt) == password
  end

  def is_admin?
    role.name == "admin"
  end

  def is_operator?
    role.name == "operator"
  end

  def logged_in?
    @logged_in
  end

  def api_login=(value)
    @logged_in = value
    @api_login = value
  end

  def verify_session(session_user_id, session_session_id, cookie_session_id)
    if self.id == session_user_id && session_session_id == cookie_session_id
      @logged_in = true
    else
      @logged_in = false
    end
    return @logged_in
  end

  def delete(new_user)
    jobs.all.each do |job|
      event = Event.find_by_name("change_user")
      event.run_event(job, new_user.id, I18n.t("users.delete_note"))
    end
    projects.all.each do |project|
      event = Event.find_by_name("change_user")
      event.run_event(project, new_user.id, I18n.t("users.delete_note"))
    end
    update_attribute(:deleted_at, Time.now)
  end
end

