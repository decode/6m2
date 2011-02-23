class AccountController < ApplicationController
  access_control do
    allow :admin, :manager, :except => [:charge, :process_charge]
    actions :index do
      allow all
    end
    actions :charge, :process_charge, :payment, :process_payment do
      allow :user, :guest
    end
    actions :delete_charge do
      allow :user, :admin
    end
  end
  
  def index
    @trades = Trade.where('user_id = ?', current_user).paginate(:page => params[:page], :per_page => 20)
    @user = current_user
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
      trade.trade_type = session[:charge_type]
      trade.user = user
      if trade.trade_type == 'point'
        rest = user.account_money - (trade.price.to_f * Setting.first.point_ratio)
        if rest >= 0
          Trade.transaction do 
            Accountlog.create! :user_id => user.id, :trade_id => trade.id, :amount => trade.price, :log_type => 'point', :description => 'request'
            flash[:notice] = t('trade.success') if trade.save!
          end
        else
          flash[:error] = t('trade.no_enough_money')
        end
      else
        Trade.transaction do 
          Accountlog.create! :user_id => user.id, :trade_id => trade.id, :amount => trade.price, :log_type => 'charge', :description => 'request'
          flash[:notice] = t('trade.success') if trade.save!
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
                user.account_credit = Setting.first.init_required_point
                user.has_role! :user
                user.has_no_role! :guest
              end
            end
            Accountlog.create! :user_id => user.id, :operator_id => current_user.id, :trade_id => trade.id, :amount => trade.price, :log_type => 'charge', :description => 'approve charge'
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
    redirect_to :controller=>'account', :action=>'approve'
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
        Accountlog.create! :user_id => user.id, :operator_id => current_user.id, :trade_id => trade.id, :amount => trade.price, :log_type => 'charge', :description => 'reject charge'
        flash[:notice] = 'reject charge!'
      end
    end
    redirect_to '/'
  end
  
  def payment
    session[:charge_type] = 'point'
    redirect_to '/' unless user_signed_in?
  end
  
  def point
    @user = User.find(params[:id])
    session[:user_edit_mode] = 'point'
    redirect_to edit_user_url(@user)
  end

  def password
    @user = User.find(params[:id])
    session[:user_edit_mode] = 'password'
    redirect_to edit_user_url(@user)
  end
    
end
