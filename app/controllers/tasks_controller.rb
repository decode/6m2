class TasksController < ApplicationController
  access_control do
    allow :admin, :manager, :user, :guest
    deny anonymous
  end

  # GET /tasks
  # GET /tasks.xml
  def index
    if params[:user_id]
      @tasks = Task.where("user_id = ?", params[:user_id]).order('created_at DESC').paginate(:page => params[:page], :per_page => 10)
    else
      if current_user.has_role? 'admin'
        @tasks = Task.where("task_type in (?) and status != 'unpublished'",['taobao', 'youa', 'paipai', 'virtual']).order('created_at DESC').paginate(:page => params[:page], :per_page => 15)
      else
        @tasks = Task.where("task_type in (?) and status = 'published' and worker_level <= ?",['taobao', 'youa', 'paipai', 'virtual'], current_user.level).order('created_at DESC').paginate(:page => params[:page], :per_page => 15)
      end
    end

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @tasks }
    end
  end

  # GET /tasks/1
  # GET /tasks/1.xml
  def show
    @task = Task.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @task }
    end
  end

  # GET /tasks/new
  # GET /tasks/new.xml
  def new
    @task = Task.new
    @task.user = current_user
    @task.task_type = "taobao"
    @task.status = 'unpublished'
    @task.worker_level = 0
    @task.task_day = 1
    @task.extra_word = false
    @task.avoid_day = 7
    #@task.task_level = 0
    @task.real_level = 0 

    respond_to do |format|
      if current_user.account_credit <= 0 and current_user.account_money <= 0
        format.html { redirect_to(:back, :notice => t('task.not_enough_point')) }
        format.xml
      else
        format.html # new.html.erb
        format.xml  { render :xml => @task }
      end
    end
  end

  # GET /tasks/1/edit
  def edit
    @task = Task.find(params[:id])
  end

  # POST /tasks
  # POST /tasks.xml
  def create
    isPass = false
    price = params[:task][:price].to_f
    unless price <= 0 or price > current_user.account_money
      @task = Task.new(params[:task])
      if @task.user.nil?
        @task.user = current_user
      end
      
      if params[:task][:published] == 'true'
        @task.publish
      end
      if !["taobao", "paipai", "youa", "virtual", "cash"].include?(@task.task_type)
        @task.task_type = "taobao"
      end
      if params[:task][:extra_word] == 'true' and params[:task][:custom_judge] == 'true'
        @task.custom_judge = true
        @task.custom_judge_content = params[:task][:custom_judge_content]
      end
      if params[:task][:transport_id].nil? or params[:task][:transport_id] == ''
        tid = generate_transport_id(params[:task][:transport])
        @task.transport, @task.transport_id = tid
        logger.info("============ Transport ID ==========" + @task.transport + "|" + @task.transport_id)
      end
      @task.point = @task.free_task? ? 0 : caculate_point(@task)

      @task.published_time = Time.now
      isPass = true
    end

    respond_to do |format|
      Task.transaction do 
        if isPass and @task.save
          spend(@task)
          format.html { redirect_to(@task, :notice => t('task.create_success')) }
          format.xml  { render :xml => @task, :status => :created, :location => @task }
        else
          format.html { redirect_to(:back, :notice => t('task.not_enough_point')) }
          format.xml  { render :xml => @task.errors, :status => :unprocessable_entity }
        end
     end
    end
  end

  # PUT /tasks/1
  # PUT /tasks/1.xml
  def update
    @task = Task.find(params[:id])
    if !["taobao", "paipai", "ebay", "virtual", "cash"].include?(params[:task][:task_type])
      params[:task][:task_type] = "taobao"
    end

    # 恢复发布点
    restore_spend(@task)

    respond_to do |format|
      Task.transaction do 
        if @task.can_modify? and @task.update_attributes(params[:task])
          spend(@task)
          format.html { redirect_to(@task, :notice => 'Task was successfully updated.') }
          format.xml  { head :ok }
        else
          format.html { render :action => "edit" }
          format.xml  { render :xml => @task.errors, :status => :unprocessable_entity }
        end
      end
    end
  end

  # DELETE /tasks/1
  # DELETE /tasks/1.xml
  def destroy
    @task = Task.find(params[:id])
    Task.transaction do 
      if @task.can_modify?
        restore_spend(@task)
        @task.destroy
      else
        flash[:error] = t('task.can_not_delete')
      end
    end

    respond_to do |format|
      format.html { redirect_to(tasks_url) }
      format.xml  { head :ok }
    end
  end
end
