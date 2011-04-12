class AccountController < ApplicationController
  access_control do
    allow :admin, :manager, :except => [:charge, :process_charge]
    actions :index do
      allow all
    end
    actions :charge, :process_charge, :payment, :process_payment, :trade_log, :task_log, :small_cash, :big_cash, :transport_list do
      allow :user, :guest
    end
    actions :delete_charge do
      allow :user, :admin
    end
  end
  
  def index
    @trades = Trade.where('user_id = ?', current_user).order('created_at DESC').paginate(:page => params[:page], :per_page => 20)
    @user = current_user
    # used? 
    #@small_cashes = Task.where('user_id = ? and task_type = ?', current_user, 'cash').paginate(:page=>params[:page], :per_page=>10)
    #@big_cashes = Issue.where('user_id = ? and itype = ?', current_user, 'cash').paginate(:page=>params[:page], :per_page=>10)
  end
  
  def show
  end

  def charge
    session[:charge_type] = 'charge'
    redirect_to '/' unless user_signed_in?
  end

  def delete_charge
    trade = Trade.find(params[:id])
    trade.destroy if trade.user == current_user and trade.trade_type == 'charge' and trade.request?
    redirect_to :controller => "account"
  end
  
  def process_charge
    unless user_signed_in? and !session[:charge_type].nil? and params[:amount].to_f > 0
      flash[:error] = t('trade.error')
    else
      user = User.where('id = ?', current_user).first
      trade = Trade.new
      trade.price = params[:amount]
      trade.transaction_id = params[:transaction_id] if params[:transaction_id]
      trade.trade_type = session[:charge_type]
      trade.user = user
      if trade.trade_type == 'point'
        rest = user.account_money - (trade.price.to_f * Setting.first.point_ratio)
        if rest >= 0
          Trade.transaction do 
            if trade.save!
              Accountlog.create! :user_id => user.id, :trade_id => trade.id, :amount => trade.price, :log_type => 'point', :description => t('trade.request_point')
              flash[:notice] = t('trade.success')
            end
          end
        else
          flash[:error] = t('trade.no_enough_money')
        end
      else
        Trade.transaction do
          if trade.save!
            Accountlog.create! :user_id => user.id, :trade_id => trade.id, :amount => trade.price, :log_type => 'charge', :description => t('trade.request_charge')
            flash[:notice] = t('trade.success') 
          end
        end
      end
    end
    redirect_to :controller => 'account'
  end

  def approve
    @trades = Trade.where('status = ? and trade_type = ?', 'request', params[:id]).paginate(:page => params[:page], :per_page => 20)
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
            user.account_money = user.account_money + trade.price.to_f
            # 如果是guest用户,自动扣去发布点所需的金额,并增加相应的发布点
            if user.has_role? 'guest'
              rest = user.account_money - (Setting.first.point_ratio * Setting.first.init_required_point)
              if rest >= 0
                user.account_money = rest
                user.account_credit = user.account_credit + Setting.first.init_required_point #fix if user has been assign credit before confirm
                user.has_role! :user
                user.has_no_role! :guest
              end
            end
            Accountlog.create! :user_id => user.id, :operator_id => current_user.id, :trade_id => trade.id, :amount => trade.price, :log_type => 'charge', :description => t('trade.approve')
            user.save!
            flash[:notice] = t('trade.approve_charge')
          # 发布点批准
          else
            rest = user.account_money - (trade.price.to_f * Setting.first.point_ratio)
            if rest >= 0
              user.account_money = rest
              user.account_credit = user.account_credit + trade.price.to_f
              user.save!
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
        Accountlog.create! :user_id => trade.user.id, :operator_id => current_user.id, :trade_id => trade.id, :amount => trade.price, :log_type => 'charge', :description => t('trade.reject')
        flash[:notice] = t('global.operate_success')
      end
    end
    redirect_to :back
  end
  
  # 金额兑换发布点
  def payment
    session[:charge_type] = 'point'
    redirect_to '/' unless user_signed_in?
  end
  
  def trade_log
    @user = User.find(params[:id])
    @trades = Accountlog.where('user_id = ?', params[:id]).order('created_at DESC').paginate(:page=>params[:page], :per_page => 15)
  end
  
  def task_log
    @user = User.find(params[:id])
    @tasks = Tasklog.where('user_id = ?', params[:id]).order('created_at DESC').paginate(:page=>params[:page], :per_page => 15)
  end

  def small_cash
    @user = User.find(params[:id])
    @tasks = Task.where('user_id = ? and task_type = ?', @user, 'cash').order('created_at DESC').paginate(:page=>params[:page], :per_page=>15)
  end

  def big_cash
    @user = User.find(params[:id])
    @issues = Issue.where('user_id = ? and itype = ?', @user, 'cash').order('created_at DESC').paginate(:page=>params[:page], :per_page=>15)
  end

  def participant
    @user = User.find(params[:id])
    @participants = @user.participants.paginate(:page=>params[:page], :per_page=>10)
  end
    
  def transport_list
    @user = User.find(params[:id])
    @transports = @user.transports.paginate(:page=>params[:page], :per_page=>15)
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

  
end
