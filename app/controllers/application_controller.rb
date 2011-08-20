class ApplicationController < ActionController::Base
  rescue_from 'Acl9::AccessDenied', :with => :access_denied

  protect_from_forgery

  #before_filter :authenticate_user!
  before_filter :set_locale
 
  def set_locale
    I18n.locale = :zh || I18n.default_locale
  end

  def caculate_point(task)
    point = 0
    unless task.free_task?
      # 按金额计算
      #step = [40, 80, 120, 200, 500, 1000, 1500]
      step = [79, 119, 179, 259, 359, 499, 699, 999, 10000]
      if task.virtual_task?
        p = [1, 2, 3, 4, 5, 6, 7] 
      else
        #p = [1, 1.5, 2, 3, 4, 5, 6]
        #p = [1, 1, 1, 1, 1, 1, 1]
        p = [1, 1.5, 2, 2.5, 3, 4, 5, 6, 7]
      end
      index = step.select{ |s| s < task.price }.length
      point = p[ index==step.length ? index-1 : index ]

      # 按完成时间计算
      day_point = {1=>0, 2=>0, 3=>0.5, 4=>1, 5=>1.5, 6=>2}
      point = point + day_point[task.task_day]

      # 附加词语
      #point = point + Setting.first.extra_word if task.extra_word

      # 自定义评价
      point = point + Setting.first.custom_judge if task.custom_judge

      # 自定义留言
      point = point + Setting.first.custom_msg if task.custom_msg

      # 自定义星级评价
      point = point + Setting.first.all_star if task.all_star

      # 接任务人等级
      level = [0, 1, 2, 3, 4, 5]
      #point = point + level[task.worker_level]
      if task.worker_level > 0
        point = point + 0.2
      end

      # 同一买家不能接任务重复天数
      avoid_day = {0=>0, 10=>0.1, 20=>0.2, 30=>0.3, 40=>0.4, 50=>0.5, 60=>0.6}
      point = point + avoid_day[task.avoid_day]
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
    
    #logger.info("spend======================== #{point}")
    price = task.price.nil? ? 0 : task.price
    res = user.account_credit - point
    if res > 0
      user.account_credit = res.round(1)
      user.payment_money = (user.payment_money - price).round(1)
      user.account_money = (user.account_money - price).round(1)
      user.save
    end
  end

  def restore_spend(task)
    user = task.user
    point = task.point
    #logger.info("restore spend========================#{point}")
    user.account_credit = user.account_credit + point
    user.payment_money = user.payment_money + task.price
    user.account_money = user.account_money + task.price
    user.save
    #
    # 需要添加用户交易记录
    #
    log = Tasklog.new
    log.task_id = task.id
    log.user_id = user.id
    log.worker_id = user.id if user
    log.price = task.price
    log.point = task.point
    log.status = task.status
    log.description = I18n.t('account.point') + ":" + (user.account_credit).to_s + "  " + I18n.t('account.account_money') + ":" + (user.account_money).to_s + "  " + I18n.t('account.restore_point') + ":" + point.to_s
    log.save!
  end

  def gain(task)
    return if task.free_task?
    setting = Setting.first
    ratio = setting.skilled_point_ratio
    lev = ([1] << [ratio]*4).flatten
    #logger.info("#{task.worker.username} score:#{lev[task.worker.level]} point:#{task.point}===========================================")
    user = task.worker
    user.score = user.score + setting.score_ratio
    real_point = task.point * lev[user.level]
    user.account_credit = user.account_credit + real_point
    user.payment_money = user.payment_money + task.price
    user.account_money = user.account_money + task.price
    user.save
    #
    # 需要添加用户交易记录
    #
    log = Tasklog.new
    log.task_id = task.id
    log.user_id = user.id
    log.worker_id = user.id if user
    log.price = task.price
    log.point = task.point
    log.status = task.status
    log.description = I18n.t('account.point') + ":" + (user.account_credit).to_s + "  " + I18n.t('account.account_money') + ":" + (user.account_money).to_s + "  " + I18n.t('account.gain_point') + ":" + real_point.to_s
    log.save!
  end

  def penalty(issue, user, point=0, money=0)
    ActiveRecord::Base.transaction do
      user.account_credit = user.account_credit - point
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
      Accountlog.create! :user_id => user.id, :user_name => user.username, :operator_id => current_user.id, :operator_name => current_user.username, :amount => point, :log_type => 'point_penalty', :description => I18n.t('trade.point_penalty') + ' ' + t('account.point') + ":" + (user.account_credit).to_s + "  " + I18n.t('account.account_money') + ":" + (user.account_money).to_s
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
