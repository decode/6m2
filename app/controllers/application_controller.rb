class ApplicationController < ActionController::Base
  rescue_from 'Acl9::AccessDenied', :with => :access_denied

  protect_from_forgery

  #before_filter :authenticate_user!

  def caculate_point(task)
    point = 1 #task.task_level + task.avoid_day + task.task_day + task.worker_level
    point = point + 1 if task.extra_word
    point = point + Setting.first.custom_judge if task.custom_judge
    return point
  end
  
  def spend(task)
    user = task.user

    # 提现不需要发布点
    if task.free_task?
      point = 0
    else
      point = caculate_point(task)
    end
    logger.info("spend======================== #{point}")
    price = task.price.nil? ? 0 : task.price
    user.account_credit = user.account_credit - point
    user.payment_money = user.payment_money - price
    user.account_money = user.account_money - price
    user.save
  end

  def restore_spend(task)
    user = task.user
    if task.free_task?
      point = 0
    else
      point = caculate_point(task)
    end
    point = caculate_point(task)
    logger.info("restore spend========================#{point}")
    user.account_credit = user.account_credit + point
    user.payment_money = user.payment_money + task.price
    user.account_money = user.account_money + task.price
    user.save
  end

  def gain(task)
    return if task.free_task?
    logger.info("#{task.worker.username} score +1 ===========================================")
    task.worker.score = task.worker.score + 1
    task.worker.save
  end

  def penalty(issue, user, point=0, money=0)
    ActiveRecord::Base.transaction do
      user.score = user.score - point
      p = Penalty.find_by_issue_id(issue.id)
      if p.nil?
        p = Penalty.new 
        p.user = user
        p.issue = issue
      end
      p.point = point
      p.money = money
      p.save
      user.save
    end
  end

  def generate_transport_id
    chars = ('0'..'9').to_a
    tid = ''
    10.downto(1) { |i| tid << chars[rand(chars.length-1)] }
    return tid
  end
  
  

  private

    def access_denied
      if current_user
        # It's presumed you have a template with words of pity and regret
        # for unhappy user who is not authorized to do what he wanted
        render :template => 'site/access_denied'
      else
        # In this case user has not even logged in. Might be OK after login.
        redirect_to new_user_session_path
      end
    end
end
