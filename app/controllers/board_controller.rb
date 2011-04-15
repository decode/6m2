class BoardController < ApplicationController
  access_control do
    allow :super, :admin, :manager, :user
    allow :user, :except => [:check_pass]
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
        @tasks = Task.where("task_type = ? and status = ?", params[:task_type], 'published').order('created_at DESC').paginate(:page => params[:page], :per_page => 10)
      else
        redirect_to '/s/access_denied'
      end
    else
      @tasks = Task.where("task_type = ? and status = ? and worker_level <= ?", params[:task_type], 'published', current_user.level).order('created_at DESC').paginate(:page => params[:page], :per_page => 10)
    end
  end

  def task_show
    session[:view_task] = 'manage'
    unless current_user.nil?
      if params[:task_type] == "task"
        @tasks = Task.where("user_id = ? and task_type != ?", current_user, 'cash').order('created_at DESC').paginate(:page => params[:page], :per_page => 10)
      end
      if params[:task_type] == "todo"
        @tasks = Task.where("worker_id = ?", current_user).order('created_at DESC').paginate(:page => params[:page], :per_page => 10)
      end
      if params[:task_type] == "cash"
        @tasks = Task.where("user_id = ? and task_type = ?", current_user, 'cash').order('created_at DESC').paginate(:page => params[:page], :per_page => 10)
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
      flash[:error] = error
    else
      Task.transaction do
        @task.worker = current_user
        @task.participant = current_user.active_participant
        @task.takeover_time = Time.now

        msg = Message.create! :title => t('message.task_takeover', :task => @task.title), :content => t('message.task_takeover_content', :task => @task.title, :link => @task.id.to_s)
        @task.user.received_messages << msg
        @task.user.save

        flash[:notice] = t('task.do_task') if @task.takeover
      end
    end
    redirect_to tasks_path
  end

  def finish_task
    @task = Task.find(params[:id])
    Task.transaction do
      @task.finished_time = Time.now
      if @task.finish
        msg = Message.create! :title => t('message.task_finish', :task => @task.title), :content => t('message.task_finish_content', :task => @task.title, :link => @task.id.to_s)
        msg.receivers << @task.user
        msg.save
        flash[:notice] = t('global.update_success')
      end
    end
    redirect_to tasks_path
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
      gain(task)
      task.confirmed_time = Time.now
      if task.over
        msg = Message.create! :title => t('message.task_confirm', :task => task.title), :content => t('message.task_confirm_content', :task => task.title, :link => task.id.to_s)
        msg.receivers << task.worker
        msg.save
        flash[:notice] = t('task.confirm_success')
      end
    end
    redirect_to tasks_url
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

  def close_transport
    tran = Transport.find(params[:id])
    if tran.close
      flash[:notice] = t('global.operate_success')
    else
      flash[:error] = t('global.operate_failed')
    end
    redirect_to :back
  end

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
    
  def search_user
    @users = User.where("username like ? and username != 'superadmin'", "%#{params[:username]}%").paginate(:page => params[:page], :per_page => 10)
    session[:search_username] = params[:username]
    render 'users/index'
  end
  

end
