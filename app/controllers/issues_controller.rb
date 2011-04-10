class IssuesController < ApplicationController
  access_control do
    allow :admin, :manager
    allow :user, :except => [:edit, :update, :destroy]
    allow :guest, :except => [:index, :edit, :update, :destroy]
  end

  access_control :secret_access?, :filter => false do
    allow :admin, :manager, :super
  end

  # GET /issues
  # GET /issues.xml
  def index
    if secret_access?
      @issues = Issue.where('itype != ?', 'cash').paginate(:page => params[:page], :per_page => 10)
    else
      @issues = Issue.where('itype != ? and user_id = ?', 'cash', current_user).paginate(:page => params[:page], :per_page => 10)
    end

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @issues }
    end
  end

  # GET /issues/1
  # GET /issues/1.xml
  def show
    @issue = Issue.find(params[:id])
    session[:issue_id] = @issue.id
    unless @issue.target_id.nil?
      @penalties = @issue.penalties
      source = @issue.get_source
      if source.class.name == Task.name
        @task = source 
        @from = @task.user
        @user = @task.worker
      end
    end

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @issue }
    end
  end

  # GET /issues/new
  # GET /issues/new.xml
  def new
    @issue = Issue.new
    unless session[:issue_type].nil? or session[:issue_task].nil?
      target = eval("#{session[:issue_type]}.find_by_id(#{session[:issue_task]})")
      if target.class.name == Task.name
        @task = target
      end
    else
      @issue.itype = 'cash'
    end
    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @issue }
    end
  end

  # GET /issues/1/edit
  def edit
    @issue = Issue.find(params[:id])
    source = @issue.get_source unless @issue.target_id.nil?
    @task = source if source.class.name == Task.name
  end

  # POST /issues
  # POST /issues.xml
  def create
    @issue = Issue.new(params[:issue])
    @issue.itype = 'normal' unless %w{normal cash}.include? @issue.itype
    unless session[:issue_type].nil? or session[:issue_task].nil?
      target = eval("#{session[:issue_type]}.find_by_id(#{session[:issue_task]})")
      @issue.add_source( target )
      target.argue if target.class.name == Task.name
    end
    
    @issue.user = current_user
    session[:issue_type] = nil
    respond_to do |format|
      ActiveRecord::Base.transaction do
        if @issue.save
          target.save if target
          format.html { redirect_to(@issue, :notice => t('issue.create')) }
          format.xml  { render :xml => @issue, :status => :created, :location => @issue }
        else
          format.html { render :action => "new", :notice => t('global.operated_failed') }
          format.xml  { render :xml => @issue.errors, :status => :unprocessable_entity }
        end
      end
    end
  end

  # PUT /issues/1
  # PUT /issues/1.xml
  def update
    @issue = Issue.find(params[:id])
    session[:issue_type] = nil

    respond_to do |format|
      if @issue.update_attributes(params[:issue])
        format.html { redirect_to(@issue, :notice => 'Issue was successfully updated.') }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @issue.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /issues/1
  # DELETE /issues/1.xml
  def destroy
    @issue = Issue.find(params[:id])
    @issue.destroy if @issue.user == current_user or current_user.has_role?('admin')

    respond_to do |format|
      format.html { redirect_to(issues_url) }
      format.xml  { head :ok }
    end
  end
end
