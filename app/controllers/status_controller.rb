class StatusController < ApplicationController
  access_control do
    allow :superadmin, :admin
    deny anonymous
  end

  def total
    @credit_users = User.where("username != 'superadmin'").order('account_credit DESC').limit(5)
    @money_users = User.where("username != 'superadmin'").order('account_money DESC').limit(5)
    @score_users = User.where("username != 'superadmin'").order('score DESC').limit(5)
    @lazy_users = User.where("username != 'superadmin'").order('sign_in_count DESC').limit(5)
    @month_tasks = Task.where(:confirmed_time => Time.now.at_beginning_of_month..Time.now.at_end_of_month).order('confirmed_time ASC')
    @month_tasks_sum = @month_tasks.sum('price')
    @month = [0]*31
    @month_tasks.each do |t|
      @month[t.confirmed_time.day-1] = @month[t.confirmed_time.day-1] + 1
    end
    @month_trades = Trade.where(:created_at => Time.now.at_beginning_of_month..Time.now.at_end_of_month).order('created_at ASC')
    @month_trades_sum = @month_trades.sum('price')
    @month_t = [0]*31
    @month_trades.each do |t|
      @month_t[t.created_at.day-1] = @month_t[t.created_at.day-1] + t.price
    end
  end

end
