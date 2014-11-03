class UsersController < ApplicationController
  before_filter :login_if_not_admin, :except => [:login, :authenticate, :logout, :show,
    :change_password, :set_password]
  before_filter :login_if_not_logged_in, :only => [:show]

  def index
    @users = User.real
    @users_deleted = User.deleted
  end

  def show
    @user = User.find(params[:id])
  end

  def new
    @user = User.new
  end


  def create
    params[:user].delete_if { |k,v| params[:user][k].blank? }
    @user = User.new(params[:user])
    if !params[:user][:password].blank?
      if params[:user][:password] == params[:user][:password_confirm]
        @user.password = @user.encrypt_password(params[:user][:password])
      else
        @user.password = nil
      end
    end
    if @user.save
      if(@user.email?)
        UserMailer.welcome_email(@user,params[:user][:password]).deliver
      end
      redirect_to :action => 'index'
      return
    end
    render :action => 'new'
  end

  def edit
    @user = User.find(params[:id])
  end


  def update
    params[:user].delete_if { |k,v| params[:user][k].blank? }
    @user = User.find(params[:id])
    if @user.update_attributes(params[:user])
      redirect_to :action => 'index'
      return
    end
    render :action => 'edit'
  end

  def delete
    @user = User.find(params[:id])
    if @current_user.id != @user.id && @current_user.is_admin?
      @user.delete(@current_user)
    else
      flash[:notice] = t("users.delete_error")
    end
    redirect_to users_path
  end

  def undelete
    @user = User.find(params[:id])
    if @current_user.id != @user.id && @current_user.is_admin?
      @user.deleted_at = nil
      @user.save
    else
      flash[:notice] = t("users.undelete_error")
    end
    redirect_to users_path
  end

  def change_password
    if @current_user.is_admin?
      @user = User.find_by_id(params[:id]) || @current_user
    else
      @user = @current_user
    end
  end

  def set_password
    params[:user].delete_if { |k,v| params[:user][k].blank? }
    if @current_user.is_admin?
      @user = User.find_by_id(params[:id]) || @current_user
    else
      @user = @current_user
    end
    if !params[:user][:password].blank?
      if params[:user][:password] == params[:user][:password_confirm]
        params[:user][:password] = @user.encrypt_password(params[:user][:password])
      else
        params[:user][:password] = nil
      end
    end
    if @user.update_attributes(params[:user])
      redirect_to params[:return_path]
      return
    end
    render :action => 'change_password'
  end

  def login
  end

  def authenticate
    username = params[:user][:username]
    password = params[:user][:password]
    @user = User.find_by_username(username)
    if !@user || !@user.authenticate(password)
      flash[:notice] = 'users.login.fail'
      session[:session_key] = nil
      redirect_to :action => 'login', :return_path => params[:return_path]
      return
    end
    session_key = Digest::MD5.hexdigest(Time.now.to_f.to_s)
    session[:session_key] = session_key
    cookies[:session_key] = session_key
    session[:user_id] = @user.id
    cookies[:user_id] = @user.id
    if !params[:return_path].blank?
      ##redirect_to params[:return_path]
      redirect_to projects_path
    else
      redirect_to projects_path
    end
  end

  def logout
    session[:session_key] = nil
    return_path = params[:return_path] || login_users_path
    redirect_to return_path
  end

end
