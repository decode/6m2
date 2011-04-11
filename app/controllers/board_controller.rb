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
    if @task.user == current_user or !@task.can_do?(current_user)
      flash[:error] = t('task.can_not_do')
    else
      Task.transaction do
        @task.worker = current_user
        @task.participant = current_user.active_participant
  
        logger.info('publish====')# if @task.takeover
        logger.info(@task.status + @task.worker.username)
        @task.takeover_time = Time.now
        flash[:notice] = t('task.do_task') if @task.takeover
      end
    end
    redirect_to tasks_path
  end

  def finish_task
    task = Task.find(params[:id])
    Task.transaction do
      task.finished_time = Time.now
      if task.finish
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

  def search_user
    @users = User.where("username like ? and username != 'superadmin'", "%#{params[:username]}%").paginate(:page => params[:page], :per_page => 10)
    session[:search_username] = params[:username]
    render 'users/index'
  end
  

end
