class UsersController < ApplicationController
  access_control do
    allow :admin, :manager
    allow :salesman, :user, :guest, :except => [:index, :destroy]
    actions :new, :create, :show do
      allow all
    end
  end

  access_control :secret_access?, :filter => false do
    allow :admin, :manager, :superadmin
  end
  
  # GET /users
  # GET /users.xml
  def index
    if current_user.has_role? 'superadmin'
      @users = User.order('created_at DESC').paginate(:page => params[:page], :per_page => 20)
    else
      @users = User.where('id != 1').order('created_at DESC').paginate(:page => params[:page], :per_page => 20)
    end
    session[:user_edit_mode] = nil

    respond_to do |format|
      format.html # index.html.haml
      format.xml  { render :xml => @users }
    end
  end

  def new
    @user = User.new

    respond_to do |format|
      format.html # new.html.haml
      format.xml  { render :xml => @user }
    end
  end
  
  def create
    @user = User.new(params[:user])
    @user.has_role! 'guest'

    respond_to do |format|
      if @user.save
        format.html { redirect_to(:back, :notice => t('site.register_success')) }
        format.xml  { render :xml => @user, :status => :created, :location => @user }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @user.errors, :status => :unprocessable_entity }
      end
    end
  end
  
  def show
    session[:user_edit_mode] = nil
    #if current_user.has_role? 'salesman'
    #  redirect_to '/m/business'
    #end
    secret_access? ? @user = User.find(params[:id]) : @user = @current_user

    @month_tasks = Task.where(:user_id => @user.id, :confirmed_time => Time.now.at_beginning_of_month..Time.now.at_end_of_month).order('confirmed_time ASC')
    @month_tasks_sum = @month_tasks.sum('price')
    @month = [0]*31
    @month_tasks.each do |t|
      @month[t.confirmed_time.day-1] = @month[t.confirmed_time.day-1] + 1
    end

    @week_tasks = Task.where(:user_id => @user.id, :confirmed_time => Time.now.at_beginning_of_week..Time.now.at_end_of_week).order('confirmed_time ASC')
    @week_tasks_sum = @week_tasks.sum('price')
    @week = [0]*7
    @week_tasks.each do |t|
      @week[t.confirmed_time.wday] = @week[t.confirmed_time.wday] + 1
    end

    @month_trades = Trade.where(:user_id => @user.id, :created_at => Time.now.at_beginning_of_month..Time.now.at_end_of_month).order('created_at ASC')
    @month_trades_sum = @month_trades.sum('price')
    @month_t = [0]*31
    @month_trades.each do |t|
      @month_t[t.created_at.day-1] = @month_t[t.created_at.day-1] + t.price
    end

    @week_trades = Trade.where(:user_id => @user.id, :created_at => Time.now.at_beginning_of_week..Time.now.at_end_of_week).order('created_at ASC')
    @week_trades_sum = @week_trades.sum('price')
    @week_t = [0]*7
    @week_trades.each do |t|
      @week_t[t.created_at.wday] = @week_t[t.created_at.wday] + t.price
    end
  end

  def edit
    if secret_access?
      @user = User.find(params[:id])
    else
      @user = @current_user
    end
    @user.operate_password = nil if session[:user_edit_mode] == 'code'
  end
  
  def update
    if secret_access?
      @user = User.find(params[:id])
    else
      @user = @current_user # makes our views "cleaner" and more consistent
    end
    log_str = t('global.modify') + t('site.user_info')
    isPass = true
    if session[:user_edit_mode] == 'code'
      isPass = false if !@user.operate_password.nil? and (params[:old_password] != @user.operate_password or current_user.has_role? 'admin')
      log_str = t('global.modify') + t('site.operate_password')
    end
    respond_to do |format|
      User.transaction do
        if isPass and @user.update_attributes(params[:user])
          if session[:user_edit_mode] == 'point'
            Accountlog.create! :user_id => @user.id, :operator_id => current_user.id, :amount => @user.account_credit, :log_type=>'credit', :description => 'modify credit'
          else
            Accountlog.create! :user_id => @user.id, :operator_id => current_user.id, :amount => 0, :log_type=>'account', :description => log_str
          end
          session[:user_edit_mode] = nil
          format.html { redirect_to(@user, :notice => t('account.update_success')) }
          format.xml  { head :ok }
        else
          format.html { redirect_to(:back, :error => t('account.update_failed')) }
          format.xml  { render :xml => @user.errors, :status => :unprocessable_entity }
        end
      end
    end
  end

  # DELETE /users/1
  # DELETE /users/1.xml
  def destroy
    @user = User.find(params[:id])
    @user.destroy

    respond_to do |format|
      format.html { redirect_to(users_url) }
      format.xml  { head :ok }
    end
  end

end
