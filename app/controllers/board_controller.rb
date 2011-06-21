class BoardController < ApplicationController
  access_control do
    allow :superadmin
    allow :admin, :manager, :user, :except => [:roles, :new_role, :create_role, :delete_role]
    allow :user, :except => [:check_pass, :roles, :new_role, :create_role, :delete_role, :accountlogs, :tasklogs]
    deny anonymous
  end

  def users
    @users = User.find :all
  end

  def service
    role = Role.where(:name => 'manager').first
    ids = role.user_ids.drop(1)
    @users = User.where(:id => ids).order("created_at DESC")#.paginate(:page => params[:page], :per_page => 20)
    role = Role.where(:name => 'admin').first
    ids = role.user_ids.drop(1)
    @admins = User.where(:id => ids).order("created_at DESC")#.paginate(:page => params[:page], :per_page => 20)
  end
  
  def big_cash
    @issues = Issue.where("itype = ?", 'cash').paginate(:page => params[:page], :per_page => 10)
  end

  def task_list
    if params[:task_type] == 'cash'
      if current_user.has_role? 'manager'
        tasks = Task.where(:task_type => [params[:task_type], 'v_'+params[:task_type]]).where("status != 'published'").order('created_at DESC')
        tasks = Task.where(:task_type => [params[:task_type], 'v_'+params[:task_type]]).where("status = 'published'").order('created_at DESC') + tasks
        @tasks = tasks.paginate(:page => params[:page], :per_page => 15)
      else
        redirect_to '/s/access_denied'
      end
    elsif params[:task_type] == "payment"
      session[:view_task] = 'payment'
      @tasks = Task.where("task_type != ? and status = ?", 'cash', 'price').group('worker_id').order('created_at DESC').paginate(:page => params[:page], :per_page => 15)
    else
      @tasks = Task.where("task_type in ( '#{params[:task_type]}', 'v_#{params[:task_type]}' ) and status = ? and worker_level <= ?", 'published', current_user.level).order('created_at DESC').paginate(:page => params[:page], :per_page => 15)
    end
  end

  def task_show
    #session[:view_task] = 'manage'
    unless current_user.nil?
      if params[:task_type] == "task"
        @tasks = Task.where("user_id = ? and task_type != ?", current_user, 'cash').order('created_at DESC').paginate(:page => params[:page], :per_page => 15)
      end
      if params[:task_type] == "todo"
        @tasks = Task.where("worker_id = ?", current_user).order('created_at DESC').paginate(:page => params[:page], :per_page => 15)
      end
      if params[:task_type] == "cash"
        @tasks = Task.where("user_id = ? and task_type = ?", current_user, 'cash').order('created_at DESC').paginate(:page => params[:page], :per_page => 15)
      end
    end
  end

  def status_task
    @tasks = Task.where("status = ?", params[:task_status]).order('created_at DESC').paginate(:page => params[:page], :per_page => 10)
  end
  
  def do_task
    @task = Task.find(params[:id])
    isPass, error = @task.can_do?(current_user)
    unless isPass
      flash[:error] = I18n.t('task.error_head') + ', ' + error
      redirect_to tasks_path
    else
      Task.transaction do
        @task.worker = current_user
        @task.participant = current_user.active_participant
        @task.takeover_time = Time.now
        @task.worker_part_id = current_user.active_participant.id
        @task.worker_part_name = current_user.active_participant.part_id

        if @task.takeover
          msg = Message.create :title => t('message.task_takeover', :task => @task.title), :content => t('message.task_takeover_content', :task => @task.title, :link => @task.id.to_s)
          msg.receivers << @task.user
          msg.save
          flash[:notice] = t('task.do_task') 
        else
          flash[:error] = t('global.operate_failed') 
        end
      end
      redirect_to '/task_show/todo'
    end
  end

  def price_task
    @task = Task.find(params[:id])
    Task.transaction do
      @task.pay_time = Time.now
      if @task.running? and @task.pricing
        msg = Message.create :title => t('message.task_pricing', :task => @task.title), :content => t('message.task_pricing_content', :task => @task.title, :link => @task.id.to_s)
        msg.receivers << @task.worker
        msg.save
        flash[:notice] = t('global.update_success')
      end
    end
    redirect_to '/task_show/todo'
  end

  def pay_task
    @task = Task.find(params[:id])
    Task.transaction do
      @task.pay_time = Time.now
      if @task.price? and @task.pay
        msg = Message.create :title => t('message.task_pay', :task => @task.title), :content => t('message.task_pay_content', :task => @task.title, :link => @task.id.to_s)
        msg.receivers << @task.user
        msg.save
        flash[:notice] = t('global.update_success')
      end
    end
    redirect_to '/task_show/todo'
  end

  def send_good
    @task = Task.find(params[:id])
    Task.transaction do
      @task.transport_time = Time.now
      if @task.cash? and @task.trans
        msg = Message.create :title => t('message.task_transport', :task => @task.title), :content => t('message.task_transport_content', :task => @task.title, :link => @task.id.to_s)
        msg.receivers << @task.worker
        msg.save
        flash[:notice] = t('global.update_success')
      end
    end
    redirect_to '/task_show/task'
  end

  def finish_task
    @task = Task.find(params[:id])
    Task.transaction do
      @task.finished_time = Time.now
      if @task.finish
        msg = Message.create :title => t('message.task_finish', :task => @task.title), :content => t('message.task_finish_content', :task => @task.title, :link => @task.id.to_s)
        msg.receivers << @task.user
        msg.save
        flash[:notice] = t('global.update_success')
      end
    end
    redirect_to '/task_show/todo'
  end

  def argue_task
    task = Task.find(params[:id])
    session[:issue_type] = task.class.name
    session[:issue_task] = task.id
    redirect_to new_issue_url
  end

  def confirm_task
    task = Task.find(params[:id])
    Task.transaction do
      # 完成任务获得积分
      task.confirmed_time = Time.now
      if task.over
        gain(task)
        msg = Message.create :title => t('message.task_confirm', :task => task.title), :content => t('message.task_confirm_content', :task => task.title, :link => task.id.to_s)
        msg.receivers << task.worker
        msg.save
        flash[:notice] = t('task.confirm_success')
      end
    end
    redirect_to '/task_show/task'
  end

  def task_issue
    issue = Issue.find(session[:issue_id])
    if issue.open?
      Issue.transaction do 
        task = issue.get_source
        if 'user' == params[:issue_source]
          # 任务发布者造成的问题,返积分给任务执行者并确认这个任务完成
          logger.info('user problem=======================')
          target_user = task.user
          Task.transaction do
            task.over
            gain(task)
          end
        else
          # 任务执行者造成的问题 
          target_user = task.worker
          Task.transaction do
            restore_spend(task) if params[:return_point]
            task.over
          end
        end
        if params[:penalty]
          penalty(issue, target_user, params[:penalty_value].to_f)
        end
        issue.fix
        issue.memo = params[:memo] if params[:memo]
        if issue.save
          flash[:notice] = t('issue.has_fixed')
        end
      end
    else
      flash[:error] = t('issue.can_not_modify')
    end
    redirect_to issues_url
  end
  
  def fix_issue
    issue = Issue.find(params[:id])
    if issue.open?
      issue.fix
      if issue.save
        flash[:notice] = t('issue.has_fixed')
      end
    else
      flash[:error] = t('issue.can_not_modify')
    end
    redirect_to issues_url
  end

  def close_issue
    issue = Issue.find(params[:id])
    issue.shutdown
    if issue.save
      flash[:notice] = t('issue.has_close')
    end
    redirect_to issues_url
  end

  # 单号购买
  def choose_transport
    tran = Transport.find(params[:id])
    if tran and buy_transport_id(current_user)
      ActiveRecord::Base.transaction do
        current_user.transports << tran
        Accountlog.create! :user_id => current_user.id, :amount => 1, :log_type => 'transport', :description => t('trade.buy_transport')
        current_user.save!
        # 超过设定购买次数关闭该运单号
        tran.close if tran.users.length >= Setting.first.times_limit
      end
      flash[:notice] = t('global.operate_success') + ', ' + t('trade.spend') + 1.to_s + t('global.yuan')
    else
      flash[:error] = t('global.operate_failed')
    end
    redirect_to :back
  end

  # 关闭单号
  def close_transport
    tran = Transport.find(params[:id])
    if tran.close
      flash[:notice] = t('global.operate_success')
    else
      flash[:error] = t('global.operate_failed')
    end
    redirect_to :back
  end

  # 重用单号
  def reuse_transport
    tran = Transport.find(params[:id])
    if tran.reuse
      flash[:notice] = t('global.operate_success')
    else
      flash[:error] = t('global.operate_failed')
    end
    redirect_to :back
  end

  # 单号审核(暂不用)
  def check_pass
    tran = Transport.find(params[:id])
    tran.check
    redirect_to :back
  end

  # 查看用户的消息
  def view_message
    mb = MessageBox.where(:user_id => current_user.id, :message_id => params[:id]).first
    mb.make_read
    msg = mb.message
    redirect_to msg
  end

  # 标记消息己读
  def make_read
    msg = Message.find(params[:id])
    msg.make_read
    redirect_to :back
  end
  
  def mb_read
    msg = MessageBox.find(params[:id])
    msg.make_read
    redirect_to :back
  end
  
  # 标记消息未读
  def make_unread
    msg = Message.find(params[:id])
    msg.make_unread
    redirect_to :back
  end

  def mb_unread
    msg = MessageBox.find(params[:id])
    msg.make_unread
    redirect_to :back
  end

  def make_delete
    mb = MessageBox.where(:user_id => current_user.id, :id => params[:id]).first
    if mb
      if mb.message.message_boxes.length == 1
        mb.message.destroy 
      else
        mb.destroy
      end
      flash[:notice] = t('global.operate_success')
      redirect_to '/m/message'
    else
      flash[:error] = t('global.operate_failed')
      redirect_to '/m/message'
    end
  end

  def mb_read_all
    current_user.message_boxes.where("status = 'unread'").each do |m|
      m.make_read
    end
    flash[:notice] = t("global.operate_success")
    redirect_to '/m/message'
  end

  # 删除所有消息
  def mb_delete_all
    current_user.message_boxes.find_each do |m|
      if m.message.message_boxes.length == 1
        m.message.destroy 
      else
        m.destroy
      end
    end
    flash[:notice] = t("global.operate_success")
    redirect_to '/m/message'
  end
  
  # 发送消息
  def message_to
    session[:message_to] = params[:id]
    redirect_to new_message_url
  end

  #
  # ==========================================
  # 角色管理
  #
  def roles
    if current_user.has_role? 'superadmin'
      @roles = Role.all
    else
      redirect_to '/'
    end
  end

  def new_role
    @role = Role.new
  end

  def create_role
    @role = Role.new(params[:role])
    if @role.save
      flash[:notice] = t('global.operate_success')
    else
      flash[:error] = t('global.operate_failed')
    end
    redirect_to '/t/roles'
  end

  def delete_role
    role = Role.find(params[:id])
    if role.destroy
      flash[:notice] = t('global.operate_success')
    else
      flash[:error] = t('global.operate_failed')
    end
    redirect_to '/t/roles'
  end
  # ===========================================
  #
  # 任务日志管理
  def tasklogs
    @tasks = Tasklog.order("created_at DESC").paginate(:page => params[:page], :per_page => 15)
    session[:view_log] = 'admin'
  end
    
  def search_task_log
    from = params[:from]
    to = params[:to]
    session[:username] = params[:username]
    session[:from] = from
    session[:to] = to
    if from.blank? or to.blank?
      @tasks= Tasklog.where(:created_at => Time.now.at_beginning_of_month..Time.now.at_end_of_month)
    else
      if from == to
        if from.nil?
          @tasks= Tasklog.all
        else
          @tasks= Tasklog.where(:created_at => from.to_datetime.at_beginning_of_day..(from.to_datetime+1.day).at_beginning_of_day)
        end
      else
        @tasks= Tasklog.where(:created_at => from.to_datetime..to.to_datetime)
      end
    end
    if params[:username].blank?
      #redirect_to '/t/tasklogs'
      @tasks = @tasks.order('created_at DESC').paginate(:page=>params[:page], :per_page => 15)
    else
      @tasks = Tasklog.where("user_name like ? or worker_name like ?", "%#{params[:username]}%", "%#{params[:username]}%").paginate(:page => params[:page], :per_page => 15) 
    end
    render 'board/tasklogs'
  end
  # ===========================================
  #
  # 帐户日志管理
  def accountlogs
    @trades = Accountlog.order('created_at DESC').paginate(:page=>params[:page], :per_page => 15)
    session[:view_log] = 'admin'
  end

  def search_account_log
    from = params[:from]
    to = params[:to]
    session[:username] = params[:username]
    session[:from] = from
    session[:to] = to
    if from.blank? or to.blank?
      @trades = Accountlog.where(:created_at => Time.now.at_beginning_of_month..Time.now.at_end_of_month)
    else
      if from == to
        if from.nil?
          @trades= Accountlog.all
        else
          @trades = Accountlog.where(:created_at => from.to_datetime.at_beginning_of_day..(from.to_datetime+1.day).at_beginning_of_day)
        end
      else
        @trades= Accountlog.where(:created_at => from.to_datetime..to.to_datetime)
      end
    end
    if params[:username].blank?
      #redirect_to '/t/accountlogs'
      @trades = @trades.order('created_at DESC').paginate(:page=>params[:page], :per_page => 15)
    else
      @trades = @trades.where('user_name like ? or operator_name like ?', "%#{params[:username]}%", "%#{params[:username]}%").order('created_at DESC').paginate(:page=>params[:page], :per_page => 15)
    end
    render 'board/accountlogs'
  end
  # ===========================================
  #
  # 用户帐号激活管理
  def active_participant
    part = Participant.find(params[:id])
    if part
      part.make_active 
      part.save
    end
    redirect_to :back
  end
    
  def search_user
    @users = User.where("username like ? and username != 'superadmin'", "%#{params[:username]}%").order('created_at DESC').paginate(:page => params[:page], :per_page => 10)
    session[:search_username] = params[:username]
    render 'users/index'
  end
  
  def range_transaction
    session[:date_from] = params[:from]
    session[:date_to] = params[:to]
    redirect_to transactions_url
  end

  def range_task
    if(params[:from].blank? or params[:to].blank?)
      flash[:error] = t('transaction.date_empty')
      redirect_to '/t/task_list/payment'
    else
      from = params[:from]
      to = params[:to]
      if from == to
        if from.nil?
          @task_list = Task.where("task_type != ? and status = ?", 'cash', 'running')
        else
          @task_list = Task.where(:takeover_time => from.to_datetime.at_beginning_of_day..(from.to_datetime+1.day).at_beginning_of_day).where("task_type != ? and status = ?", 'cash', 'running')
        end
      else
        @task_list = Task.where(:takeover_time => from.to_datetime..to.to_datetime).where("task_type != ? and status = ?", 'cash', 'running')
      end
      @tasks = @task_list.group('worker_id').order('created_at DESC').paginate(:page => params[:page], :per_page => 20)
      @current_amount = @tasks.sum('price')
      render 'tasks/_tasks'
    end
  end

  def export_transaction
    headers['Content-Type'] = "application/vnd.ms-excel"
    headers['Content-Disposition'] = 'attachment; filename="transaction-export.xls"'
    headers['Cache-Control'] = ''
    if session[:date_from].blank? or session[:date_to].blank?
      @records = Transaction.order('created_at DESC')  
    else
      @records = Transaction.where(:trade_time => session[:date_from]..session[:date_to]).order('created_at DESC')  
    end
  end

  def export_accountlog
    headers['Content-Type'] = "application/vnd.ms-excel"
    headers['Content-Disposition'] = 'attachment; filename="account-export.xls"'
    headers['Cache-Control'] = ''
    from = session[:from]
    to = session[:to]
    if from.blank? or to.blank?
      @trades = Accountlog.where(:created_at => Time.now.at_beginning_of_month..Time.now.at_end_of_month)
    else
      if from == to
        if from.nil?
          @trades = Accountlog.all
        else
          @trades = Accountlog.where(:created_at => from.to_datetime.at_beginning_of_day..(from.to_datetime+1.day).at_beginning_of_day)
        end
      else
        @trades= Accountlog.where(:created_at => from.to_datetime..to.to_datetime)
      end
    end
    username = session[:username]
    if username.blank?
      @records = @trades.order('created_at DESC')
    else
      @records = @trades.where('user_name like ? or operator_name like ?', "%#{username}%", "%#{username}%").order('created_at DESC')
    end
  end
  
  def export_tasklog
    headers['Content-Type'] = "application/vnd.ms-excel"
    headers['Content-Disposition'] = 'attachment; filename="task-export.xls"'
    headers['Cache-Control'] = ''
    from = session[:from]
    to = session[:to]
    if from.blank? or to.blank?
      @tasks = Tasklog.where(:created_at => Time.now.at_beginning_of_month..Time.now.at_end_of_month)
    else
      if from == to
        if from.nil?
          @tasks = Tasklog.all
        else
          @tasks = Tasklog.where(:created_at => from.to_datetime.at_beginning_of_day..(from.to_datetime+1.day).at_beginning_of_day)
        end
      else
        @tasks = Tasklog.where(:created_at => from.to_datetime..to.to_datetime)
      end
    end
    username = session[:username]
    if username.blank?
      @records = @tasks.order('created_at DESC')
    else
      @records = @tasks.where('user_name like ? or operator_name like ?', "%#{username}%", "%#{username}%").order('created_at DESC')
    end
  end
end
