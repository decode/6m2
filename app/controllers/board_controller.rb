class BoardController < ApplicationController
  access_control do
    allow :super, :admin, :manager, :user
    deny anonymous
  end

  def users
    @users = User.find :all
  end

  def big_cash
    @issues = Issue.where("itype = ?", 'cash').paginate(:page => params[:page], :per_page => 10)
  end

  def task_list
    @tasks = Task.where("task_type = ? and status = ? and task_level <= ?", params[:task_type], 'published', current_user.level).paginate(:page => params[:page], :per_page => 10)
  end

  def task_show
    unless current_user.nil?
      if params[:task_type] == "task"
        @tasks = Task.where("user_id = ? and task_type != ?", current_user, 'cash').paginate(:page => params[:page], :per_page => 10)
      end
      if params[:task_type] == "todo"
        @tasks = Task.where("worker_id = ?", current_user).paginate(:page => params[:page], :per_page => 10)
      end
      if params[:task_type] == "cash"
        @tasks = Task.where("user_id = ? and task_type = ?", current_user, 'cash').paginate(:page => params[:page], :per_page => 10)
      end
    end
  end

  def status_task
    @tasks = Task.where("status = ?", params[:task_status]).paginate(:page => params[:page], :per_page => 10)
  end
  

  def do_task
    @task = Task.find(params[:id])
    if @task.user == current_user
      flash[:error] = t('task.self_task')
    else
      Task.transaction do
        @task.worker = current_user
  
        logger.info('publish====') if @task.takeover
        logger.info(@task.status + @task.worker.username)
        @task.takeover_time = Time.now
        flash[:notice] = t('task.do_task') if @task.save
      end
    end
    redirect_to tasks_path
  end

  def finish_task
    task = Task.find(params[:id])
    Task.transaction do
      task.finish
      @task.finished_time = Time.now
      if task.save
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
      task.over
      # 完成任务获得积分
      gain(task)
      @task.confirmed_time = Time.now
      if task.save
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
            task.save
            gain(task)
          end
        else
          # 任务执行者造成的问题 
          target_user = task.worker
          Task.transaction do
            restore_spend(task) if params[:return_point]
            task.over
            task.save
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

  def search_user
    @users = User.where("username like ?", "%#{params[:username]}%").paginate(:page => params[:page], :per_page => 10)
    session[:search_username] = params[:username]
    render 'users/index'
  end
  

end
