class ApplicationController < ActionController::Base
  rescue_from 'Acl9::AccessDenied', :with => :access_denied

  protect_from_forgery

  #before_filter :authenticate_user!

  def caculate_point(task)
    point = 0
    unless task.free_task?
      # 按金额计算
      step = [40, 80, 120, 200, 500, 1000, 1500]
      if task.virtual_task?
        p = [1, 2, 3, 4, 5, 6, 7] 
      else
        p = [1, 1.5, 2, 3, 4, 5, 6]
      end
      index = step.select{ |s| s < task.price }.length
      point = p[ index==step.length ? index-1 : index ]

      # 按完成时间计算
      point = point + task.task_day - 1

      # 附加词语
      #point = point + Setting.first.extra_word if task.extra_word

      # 自定义评价
      point = point + Setting.first.custom_judge if task.custom_judge

      # 接任务人等级
      level = [0, 1, 2, 3, 4, 5]
      #point = point + level[task.worker_level]
      if task.worker_level > 0
        point = point + 0.2
      end
    end
    return point
  end
  
  def spend(task)
    user = task.user

    # 提现不需要发布点
    #if task.free_task?
      #point = 0
    #else
      #point = caculate_point(task)
    #end
    #task.point = point
    #task.save
    point = task.point
    
    logger.info("spend======================== #{point}")
    price = task.price.nil? ? 0 : task.price
    res = user.account_credit - point
    if res > 0
      user.account_credit = res
      user.payment_money = user.payment_money - price
      user.account_money = user.account_money - price
      user.save
    end
  end

  def restore_spend(task)
    user = task.user
    point = task.point
    logger.info("restore spend========================#{point}")
    user.account_credit = user.account_credit + point
    user.payment_money = user.payment_money + task.price
    user.account_money = user.account_money + task.price
    user.save
  end

  def gain(task)
    return if task.free_task?
    lev = [1, 0.8, 0.8, 0.8, 0.8, 0.8]
    logger.info("#{task.worker.username} score:#{lev[task.worker.level]} point:#{task.point}===========================================")
    user = task.worker
    task.worker.score = task.worker.score + lev[task.worker.level]
    task.worker.account_credit = task.worker.account_credit + task.point
    user.payment_money = user.payment_money + task.price
    task.worker.account_money = task.worker.account_money + task.price
    task.worker.save
    #
    # 需要添加用户交易记录
    #
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

  def buy_transport_id(user)
    price = 1 #Setting.first.transport_price
    if user.account_money > price
      user.account_money = user.account_money - price
      return true
    end
    return false
  end
  
  def gen_chars(length, chars)
    tid = ''
    length.downto(1) { |i| tid << chars[rand(chars.length-1)] }
    return tid
  end

  def gen_string(str)
    return str[rand(str.length)] 
  end

  def generate_transport_id(tran_type)
    num_chars = ('0'..'9').to_a
    ab_chars = ('A'..'Z').to_a
    t = %w{yt st zt yd sf ems}
    unless t.include? tran_type
      tran_type = gen_string(t)
    end
    tid = case tran_type
          when 'yt'
            [tran_type, gen_chars(1, ab_chars) + gen_chars(9, num_chars)]
          when 'st'
            head = ["36", "26", "58"]
            [tran_type, gen_string(head) + gen_chars(10, num_chars)]
          when 'zt'
            head = ['6800', '2008']
            [tran_type, gen_string(head) + gen_chars(8, num_chars)]
          when 'yd'
            head = ["10", "12"]
            [tran_type, gen_string(head) + gen_chars(11, num_chars)]
          when 'sf'
            head = %w{10 20 21 22 23 24 25 27 28 29 31 33
          35 37 39 41 42 43 45 47 48 51 52 53 54 55 56
          57 58 59 63 66 69 71 72 73 74 75 76 77 79 81
          82 83 85 87 88 89 90 91 93 95 97 98 99 }
            chars = ('1' .. '5').to_a
            [tran_type, gen_string(head) + gen_chars(1, chars) + gen_chars(9, num_chars)]
          when 'ems'
            [tran_type, 'E' + gen_chars(1, ab_chars) + gen_chars(9, num_chars) + 'CN']
          end
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
