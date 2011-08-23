class TasksController < ApplicationController
  access_control do
    allow :admin, :manager, :user, :guest
    deny anonymous
  end

  # GET /tasks
  # GET /tasks.xml
  def index
    session[:view_task] = 'normal'
    if params[:user_id]
      @tasks = Task.where("user_id = ?", params[:user_id]).order('created_at DESC').paginate(:page => params[:page], :per_page => 15)
    else
      status = %w(taobao youa paipai v_taobao v_youa v_paipai)
      if current_user.has_role? 'admin' or current_user.has_role? 'manager'
        #@tasks = Task.where("task_type in (?) and status = 'published'",['taobao', 'youa', 'paipai', 'v_taobao', 'v_youa', 'v_paipai']).order('created_at DESC').paginate(:page => params[:page], :per_page => 15)
        tasks = Task.where("task_type in (?) and status != 'published'", status).order('created_at DESC')
        tasks = Task.where("task_type in (?) and status = 'published'", status).order('created_at DESC') + tasks
        @tasks = tasks.paginate(:page => params[:page], :per_page => 15)
      else
        #@tasks = Task.where("task_type in (?) and status = 'published' and worker_level <= ?",['taobao', 'youa', 'paipai', 'v_taobao', 'v_youa', 'v_paipai'], current_user.level).order('created_at DESC').paginate(:page => params[:page], :per_page => 15)
        tasks = Task.where("task_type in (?) and status != 'published' and worker_level <= ?", status, current_user.level).order('created_at DESC')
        tasks = Task.where("task_type in (?) and status = 'published' and worker_level <= ?", status, current_user.level).order('created_at DESC') + tasks
        @tasks = tasks.paginate(:page => params[:page], :per_page => 15)
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

    if @task.can_view?(current_user)
      respond_to do |format|
        format.html # show.html.erb
        format.xml  { render :xml => @task }
      end
    else
      respond_to do |format|
        format.html { redirect_to(:back, :notice => t('site.access_denied')) }
      end
    end
  end

  # GET /tasks/new
  # GET /tasks/new.xml
  def new
    isPass = true
    if current_user.active_shop.nil? or (current_user.account_credit <= 0 and current_user.account_money <= 0)
      isPass = false
      if current_user.active_shop.nil?
        notice = t('task.not_bind_shop') 
      else
        notice = t('task.not_enough_point')
      end
    else
      @task = Task.new
      @task.user = current_user
      @task.task_type = current_user.active_shop.part_type
      @task.status = 'unpublished'
      #@task.price = 10
      @task.worker_level = 0
      @task.task_day = 1
      @task.extra_word = false
      @task.avoid_day = 0
      #@task.task_level = 0
      @task.real_level = 0 
      @task.shop = current_user.active_shop.name if current_user.active_shop

      s = {'taobao' => t('participant.taobao'), 'paipai' => t('participant.paipai'), 'youa' => t('participant.youa'=>'youa')}
      @part_type = current_user.active_shop.part_type
      @local_type = s[@part_type]
    end

    respond_to do |format|
      unless isPass        
        flash[:error] = notice
        if current_user.active_shop.nil?
          format.html { redirect_to(participants_path) }
        else
          format.html { redirect_to(:back) }
        end
        format.xml
      else
        format.html # new.html.erb
        format.xml  { render :xml => @task }
      end
    end
  end

  # GET /tasks/1/edit
  def edit
    s = {'taobao' => t('participant.taobao'), 'paipai' => t('participant.paipai'), 'youa' => t('participant.youa'=>'youa')}
    @part_type = current_user.active_shop.part_type
    @local_type = s[@part_type]

    @task = Task.find(params[:id])
    unless @task.can_modify?
      flash[:error] = I18n.t('task.can_not_modify')
      redirect_to :back
    end
  end

  # POST /tasks
  # POST /tasks.xml
  def create
    isPass = false
    price = params[:task][:price].to_f
    if price > 0 and price <= current_user.account_money and (current_user.operate_password.nil? or params[:operate_password] == current_user.operate_password)
      @task = Task.new(params[:task])
      if @task.user.nil?
        @task.user = current_user
      end
      
      #logger.info("============ Task Status ==========" + @task.status)
      #if params[:task][:published] == 'true'
      #@task.publish
      #end
      
      if !["taobao", "paipai", "youa", "cash"].include?(@task.task_type)
        @task.task_type = "taobao"
      end
      if params[:virtual] == '1' and @task.task_type != "cash"
        @task.task_type = "v_" + @task.task_type
      end

      # 附加评价
      #if params[:task][:extra_word] == 'true' and params[:task][:custom_judge] == 'true'
      if params[:task][:custom_judge] == 'true'
        # bug?? extra_word not set
        @task.custom_judge = true
        @task.custom_judge_content = params[:task][:custom_judge_content]
      end

      # 自动生成单号
      if params[:task][:tran_id].nil? or params[:task][:tran_id] == ''
        tid = generate_transport_id(params[:task][:tran_type])
        #@task.tran_type, @task.transport_id = tid
        tran = Transport.where(:tran_type => tid[0], :tran_id=> tid[1]).first
        if tran
          tid = generate_transport_id(params[:task][:tran_type])
        end
        @task.tran_type, @task.tran_id = tid

        #logger.info("============ Transport ID ==========" + @task.tran_type + "|" + @task.tran_id)
      else
        # 手工填写单号
        tran_type = params[:task][:tran_type]
        tran_id = params[:task][:tran_id]
        tran = Transport.where(:tran_type => tran_type, :tran_id => tran_id).first
        @task.tran_type = tran_type
        @task.tran_id = tran_id
        @task.transport = tran if tran
      end

      # 计算任务点
      #@task.point = caculate_point(@task)
      # 绑定店铺
      @task.shop = current_user.active_shop.part_id

      @task.published_time = Time.now
      isPass = true
    end

    respond_to do |format|
      Task.transaction do 
        if isPass and @task.publish
          spend(@task)
          format.html { redirect_to(@task, :notice => t('task.create_success')) }
          format.xml  { render :xml => @task, :status => :created, :location => @task }
        else
          format.html {
            logger.error("Task Creation Error:  [" + current_user.username + "]  " + params[:task].to_s)
            flash[:error] = t('global.operate_failed') + ', ' + t('task.check_store')
            redirect_to(:back ) }
          format.xml  { render :xml => @task.errors, :status => :unprocessable_entity }
        end
     end
    end
  end

  # PUT /tasks/1
  # PUT /tasks/1.xml
  def update
    @task = Task.find(params[:id])
    if !["taobao", "paipai", "ebay", "v_taobao", "v_paipai", "v_youa", "cash"].include?(params[:task][:task_type])
      params[:task][:task_type] = "taobao"
    end

    isPass = false

    # 恢复发布点
    restore_spend(@task)
    t = Task.new(params[:task])
    point = caculate_point(t)
    if t.can_create?(current_user, params[:operate_password])
      isPass = point < current_user.account_credit    
    end

    respond_to do |format|
      Task.transaction do 
        if isPass and @task.can_modify? and @task.update_attributes(params[:task])
          spend(@task)
          format.html { redirect_to(@task, :notice => t('global.operate_success')) }
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
