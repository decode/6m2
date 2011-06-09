class StatusController < ApplicationController
  def total
    @credit_users = User.order('account_credit DESC').limit(20)
    @money_users = User.order('account_money DESC').limit(20)
    @score_users = User.order('score DESC').limit(20)
    @lazy_users = User.order('last_sign_in_at ASC').limit(20)
  end

end
