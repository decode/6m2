class UsersController < ApplicationController
  access_control do
    allow :admin, :manager
    allow :user, :guest, :except => [:index, :destroy]
    actions :new, :create, :show do
      allow all
    end
  end

  access_control :secret_access?, :filter => false do
    allow :admin, :manager, :super
  end
  
  # GET /users
  # GET /users.xml
  def index
    if current_user.has_role? 'super'
      @users = User.all.paginate(:page => params[:page], :per_page => 20)
    else
      @users = User.where('id != 1').paginate(:page => params[:page], :per_page => 20)
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
    #if @user.save
    #  flash[:notice] = "Account registered!"
    #  redirect_back_or_default account_url
    #else
    #  render :action => :new
    #end
    respond_to do |format|
      if @user.save
        format.html { redirect_to(@user, :notice => 'User was successfully created.') }
        format.xml  { render :xml => @user, :status => :created, :location => @user }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @user.errors, :status => :unprocessable_entity }
      end
    end
  end
  
  def show
    session[:user_edit_mode] = nil
    if secret_access?
      @user = User.find(params[:id])
      @trades = Trade.where('user_id = ?', @user).paginate(:page => params[:page], :per_page => 20)
    else
      @user = @current_user
      @trades = Trade.where('user_id = ?', @user).paginate(:page => params[:page], :per_page => 20)
    end
  end

  def edit
    if secret_access?
      @user = User.find(params[:id])
    else
      @user = @current_user
    end
  end
  
  def update
    if secret_access?
      @user = User.find(params[:id])
    else
      @user = @current_user # makes our views "cleaner" and more consistent
    end
    respond_to do |format|
      User.transaction do
        if @user.update_attributes(params[:user])
          if session[:user_edit_mode] == 'point'
            Accountlog.create! :user_id => @user.id, :operator_id => current_user.id, :amount => @user.account_credit, :log_type=>'credit', :description => 'modify credit'
          end
          logger.info('update user credit')
          session[:user_edit_mode] = nil
          format.html { redirect_to(@user, :notice => 'User was successfully updated.') }
          format.xml  { head :ok }
        else
          format.html { render :action => "edit" }
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
