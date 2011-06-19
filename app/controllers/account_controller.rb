class AccountController < ApplicationController
  access_control do
    allow :admin, :manager, :except => [:charge, :process_charge]
    actions :index do
      allow all
    end
    actions :charge, :process_charge, :payment, :process_payment, :trade_log, :task_log, :small_cash, :big_cash, :transport_list, :operate_password, :message, :participant, :business, :point_money, :score_point do
      allow :user, :guest, :salesman
    end
    actions :delete_charge do
      allow :user, :admin
    end
  end

  access_control :secret_access?, :filter => false do
    allow :admin, :manager, :superadmin
  end
  
  def index
    @trades = Trade.where('user_id = ?', current_user).order('created_at DESC').paginate(:page => params[:page], :per_page => 20)
    @user = current_user
  end
  
  def show
  end

  def charge
    session[:charge_type] = 'charge'
    redirect_to '/' unless user_signed_in?
    @user = current_user
  end

  def delete_charge
    trade = Trade.find(params[:id])
    #trade.destroy if trade.user == current_user and trade.trade_type == 'charge' and trade.request?
    trade.destroy if (trade.user == current_user or current_user.has_role?('admin')) and trade.request?
    redirect_to "/m/approve/charge"
  end
  
  def process_charge
    unless user_signed_in? and !session[:charge_type].nil? and params[:amount].to_f > 0
      flash[:error] = t('trade.error')
    else
      user = User.where('id = ?', current_user).first
      trade = Trade.new
      trade.price = params[:amount].to_f
      trade.transaction_id = params[:transaction_id] if params[:transaction_id]
      trade.trade_type = session[:charge_type]
      trade.user = user
      
      if trade.trade_type == 'point'
        rest = user.account_money - (trade.price * Setting.first.point_ratio)
        if rest >= 0
          Trade.transaction do 
            if trade.save!
              Accountlog.create! :user_id => user.id, :user_name => user.username, :trade_id => trade.id, :amount => trade.price, :log_type => 'point', :description => t('trade.request_point') + ' ' + t('account.point') + ":" + (user.account_credit).to_s + "  " + I18n.t('account.account_money') + ":" + (user.account_money).to_s
              flash[:notice] = t('trade.success')
            end
          end
        else
          flash[:error] = t('trade.no_enough_money')
        end
      elsif trade.trade_type == 'recyling'
        rest = user.account_credit - trade.price
        if rest >= 0 and trade.price >= Setting.first.recyling_point
          Trade.transaction do 
            if trade.save!
              Accountlog.create! :user_id => user.id, :user_name => user.username, :trade_id => trade.id, :amount => trade.price, :log_type => 'recyling', :description => t('trade.request_recyling') + ' ' + t('account.point') + ":" + (user.account_credit).to_s + "  " + I18n.t('account.account_money') + ":" + (user.account_money).to_s
              flash[:notice] = t('trade.success')
            end
          end
        else
          flash[:error] = t('trade.out_point')
        end
      elsif trade.trade_type == 'score'
        rest = user.score - trade.price
        if rest >= 0 and trade.price >= Setting.first.score_point
          Trade.transaction do 
            if trade.save!
              Accountlog.create! :user_id => user.id, :user_name => user.username, :trade_id => trade.id, :amount => trade.price, :log_type => 'score', :description => t('trade.score_point') + ' ' + t('account.point') + ":" + (user.account_credit).to_s + "  " + I18n.t('account.account_money') + ":" + (user.account_money).to_s + I18n.t('account.score') + ":" + (user.score).to_s
              flash[:notice] = t('trade.success')
            end
          end
        else
          flash[:error] = t('trade.out_score')
        end
      else
        Trade.transaction do
          if trade.save!
            Accountlog.create! :user_id => user.id, :user_name => user.username, :trade_id => trade.id, :amount => trade.price, :log_type => 'charge', :description => t('trade.request_charge') + ' ' + t('account.point') + ":" + (user.account_credit).to_s + "  " + I18n.t('account.account_money') + ":" + (user.account_money).to_s
            flash[:notice] = t('trade.success') 
          end
        end
      end
    end
    redirect_to :controller => 'account'
  end

  def approve
    @trades = Trade.where('status = ? and trade_type = ?', 'request', params[:id]).order('created_at DESC').paginate(:page => params[:page], :per_page => 20)
  end

  def approve_charge
    trade = Trade.find_by_id(params[:id])
    @transaction = Transaction.new
    @transaction.trade_time = Time.now
    @transaction.tid = trade.transaction_id
    @transaction.account_name = trade.user.username
    @transaction.amount = trade.price
    session[:trade_id] = trade.id
    render 'transactions/_form'
  end
  
  def approve_pass
    trade = Trade.find_by_id(params[:id])
    if trade.nil?
      flash[:error] = t('trade.trade_not_found')
    else
      user = trade.user
      ActiveRecord::Base.transaction do
        trade.approve
        if trade.save
          if trade.trade_type == 'charge'
            user.account_money = user.account_money + trade.price
            # 如果是guest用户,自动扣去发布点所需的金额,并增加相应的发布点
            # update: 根据需求取消,并赠送发布点
            if user.has_role? 'guest'
              user.account_credit = user.account_credit + Setting.first.init_gift_point
              user.has_role! :user
              user.has_no_role! :guest
            end
            if user.save
              Accountlog.create! :user_id => user.id, :user_name => user.username, :operator_id => current_user.id, :operator_name => current_user.username, :trade_id => trade.id, :amount => trade.price, :log_type => 'charge', :description => t('trade.approve') + ' ' + t('account.point') + ":" + (user.account_credit).to_s + "  " + I18n.t('account.account_money') + ":" + (user.account_money).to_s
              flash[:notice] = t('trade.approve_charge')
            else
              flash[:error] = t('global.operate_failed')
            end


          # 发布点回收
          elsif trade.trade_type == 'recyling'
            user.account_money = user.account_money + (trade.price * Setting.first.recyling_point_ratio)
            user.account_credit = user.account_credit - trade.price
            if user.save
              Accountlog.create! :user_id => user.id, :user_name => user.username, :operator_id => current_user.id,:operator_name => current_user.username, :trade_id => trade.id, :amount => trade.price, :log_type => 'recyling', :description => t('trade.approve') + ' ' + t('account.point') + ":" + (user.account_credit).to_s + "  " + I18n.t('account.account_money') + ":" + (user.account_money).to_s
              flash[:notice] = t('global.operate_success')
            else
              flash[:error] = t('global.operate_failed')
            end


          # 积分兑换
          elsif trade.trade_type == 'score'
            user.account_credit = user.account_credit + (trade.price/Setting.first.score_point)
            user.score = user.score - trade.price
            if user.save
              Accountlog.create! :user_id => user.id, :user_name => user.username, :operator_id => current_user.id, :operator_name => current_user.username, :trade_id => trade.id, :amount => trade.price, :log_type => 'score', :description => t('trade.approve') + ' ' + t('account.point') + ":" + (user.account_credit).to_s + "  " + I18n.t('account.account_money') + ":" + (user.account_money).to_s + I18n.t('account.score') + ":" + (user.score).to_s
              flash[:notice] = t('global.operate_success')
            else
              flash[:error] = t('global.operate_failed')
            end


          # 发布点批准
          else
            rest = user.account_money - (trade.price * Setting.first.point_ratio)
            if rest >= 0
              user.account_money = rest
              user.account_credit = user.account_credit + trade.price
              user.save!
              Accountlog.create! :user_id => user.id, :user_name => user.username, :operator_id => current_user.id, :operator_name => current_user.username, :trade_id => trade.id, :amount => trade.price, :log_type => 'point', :description => t('trade.approve') + ' ' + t('account.point') + ":" + (user.account_credit).to_s + "  " + I18n.t('account.account_money') + ":" + (user.account_money).to_s
              flash[:notice] = t('trade.approve_charge')
            else
              flash[:error] = t('trade.no_enough_money')
            end
          end
        end
      end
    end
    redirect_to :back
  end

  def approve_reject
    trade = Trade.find(params[:id])
    if trade.nil?
      flash[:error] = t('trade.trade_not_found')
      redirect_to '/'
    end
    Trade.transaction do
      trade.reject
      if trade.save
        Accountlog.create! :user_id => trade.user.id, :user_name => current_user.username, :operator_id => current_user.id, :operator_name => current_user.username, :trade_id => trade.id, :amount => trade.price, :log_type => trade.trade_type, :description => t('trade.reject')
        flash[:notice] = t('global.operate_success')
      end
    end
    redirect_to :back
  end
  
  # 金额兑换发布点
  def payment
    session[:charge_type] = 'point'
    redirect_to '/' unless user_signed_in?
    @user = current_user
  end

  # 发布点回收
  def point_money
    session[:charge_type] = 'recyling'
    if current_user.account_credit < Setting.first.recyling_point
      flash[:error] = t('account.not_enough_recyling_point')
      redirect_to :back
    end
    @user = current_user
  end

  # 积分兑换发布点
  def score_point
    session[:charge_type] = 'score'
    setting = Setting.first
    if setting.score_point > current_user.score - setting.class1
      flash[:error] = t('account.not_enough_score')
      redirect_to :back
    end
    @user = current_user
  end

  # 充值记录
  def charge_log
    secret_access? ? @user = User.find(params[:id]) : @user = @current_user
    @trades = Trade.where('user_id = ?', @user).order('created_at DESC').paginate(:page => params[:page], :per_page => 20)
  end

  # 交易记录
  def trade_log
    @user = User.find(params[:id])
    @trades = Accountlog.where('user_id = ?', params[:id]).order('created_at DESC').paginate(:page=>params[:page], :per_page => 15)
    session[:view_log] = 'user'
  end
  
  # 任务记录
  def task_log
    @user = User.find(params[:id])
    @tasks = Tasklog.where('user_id = ?', params[:id]).order('created_at DESC').paginate(:page=>params[:page], :per_page => 15)
    session[:view_log] = 'user'
  end

  # 小额提现
  def small_cash
    session[:view_task] = 'cash'
    @user = User.find(params[:id])
    @tasks = Task.where('user_id = ? and task_type = ?', @user, 'cash').order('created_at DESC').paginate(:page=>params[:page], :per_page=>15)
  end

  # 大额提现
  def big_cash
    @user = User.find(params[:id])
    @issues = Issue.where('user_id = ? and itype = ?', @user, 'cash').order('created_at DESC').paginate(:page=>params[:page], :per_page=>15)
  end

  # 买号店铺绑定
  def participant
    if current_user.has_role? 'admin'
      @user = User.find(params[:id])
    else
      @user = current_user
    end
    @participants = @user.participants.where("role_type = 'customer'").order("active DESC").paginate(:page=>params[:page], :per_page=>10)
    @shops = @user.participants.where("role_type = 'shop'").order("active DESC").paginate(:page => params[:page], :per_page => 10)
  end

  def parts
    @participants = current_user.participants.where('role_type = ?', params[:id]).paginate(:page=>params[:page], :per_page=>10)
  end
    
  def transport_list
    @user = User.find(params[:id])
    @transports = @user.transports.paginate(:page=>params[:page], :per_page=>15)
  end

  def message
    @messageboxes = MessageBox.where(:user_id => current_user).order('created_at DESC').paginate(:page => params[:page], :per_page => 15)
  end
  
  # 业务员报账
  def business
    id = params[:id]
    if current_user.has_role? 'salesman'
      session[:transaction_mode] = 'sales' 
      id = current_user.id
    end
    @user = current_user
    @trans = Transaction.where(:sales_id => id, :trade_time => Time.now.at_beginning_of_month..Time.now.at_end_of_month)
    @transactions = @trans.paginate(:page => params[:page], :per_page => 20)
    @salary = @trans.sum("amount")
    @last_trans = Transaction.where(:sales_id => id, :trade_time => 1.month.ago.at_beginning_of_month..1.month.ago.at_end_of_month)
    @last_salary = @last_trans.sum("amount")
  end
  
  # 修改用户的发布点
  def point
    @user = User.find(params[:id])
    session[:user_edit_mode] = 'point'
    redirect_to edit_user_url(@user)
  end

  # 修改用户的密码
  def password
    @user = User.find(params[:id])
    session[:user_edit_mode] = 'password'
    redirect_to edit_user_url(@user)
  end

  # 修改用户的角色
  def role
    @user = User.find(params[:id])
    session[:user_edit_mode] = 'role'
    redirect_to edit_user_url(@user)
  end

  # 修改用户的积分
  def score
    @user = User.find(params[:id])
    session[:user_edit_mode] = 'score'
    redirect_to edit_user_url(@user)
  end

  # 激活用户
  def confirm
    user = User.find(params[:id])
    user.confirm!
    redirect_to :back
  end

  # 设置操作码
  def operate_password
    if params[:id] and current_user.has_role? 'admin'
      @user = User.find(params[:id])
    else
      @user = current_user
    end
    session[:user_edit_mode] = 'code'
    redirect_to edit_user_url(@user)
  end
  
end
