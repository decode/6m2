class TransactionsController < ApplicationController
  access_control do
    allow :admin, :accountant
    allow :salesman, :except => [:edit, :update, :destroy]
    deny anonymous
  end

  autocomplete :user, :username

  after_filter :clean_session
  def clean_session
    session[:trade_id] = nil
  end

  # GET /transactions
  # GET /transactions.xml
  def index
    session[:operate_mode] = nil
    if current_user.has_role? 'admin' or current_user.has_role? 'accountant'
      @transactions = Transaction.order('trade_time DESC').paginate(:page => params[:page], :per_page => 20)
      session[:transaction_mode] = nil
    else
      @transactions = Transaction.where('sales_id = ?', current_user.id).order('trade_time DESC').paginate(:page => params[:page], :per_page => 20)
      session[:transaction_mode] = 'sales'
    end

    @trans = Transaction.where(:trade_time => Time.now.at_beginning_of_month..Time.now.at_end_of_month)
    @current_amount = @trans.sum('amount')

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @transactions }
    end
  end

  # GET /transactions/1
  # GET /transactions/1.xml
  def show
    @transaction = Transaction.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @transaction }
    end
  end

  # GET /transactions/new
  # GET /transactions/new.xml
  def new
    @transaction = Transaction.new
    @transaction.trade_time = Time.now

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @transaction }
    end
  end

  # GET /transactions/1/edit
  def edit
    @transaction = Transaction.find(params[:id])
    session[:operate_mode] = 'edit'
  end

  # POST /transactions
  # POST /transactions.xml
  def create
    session[:operate_mode] = nil
    isPass = true
    if session[:transaction_mode] == 'sales'
      @transaction = Transaction.where('tid = ?', params[:transaction][:tid]).first
      if @transaction
        unless @transaction.sales.nil?
          flash[:error] = t('transaction.has_sales') 
          isPass = false
        else
          @transaction.sales = current_user
        end
      else 
        #@transaction = Transaction.new(params[:transaction])
        flash[:error] = t('transaction.no_tid')
        isPass = false 
      end
    else
      @transaction = Transaction.where('tid = ?', params[:transaction][:tid]).first
      if @transaction
        flash[:error] = t('transaction.exist_tid')
        isPass = false
      else 
        @transaction = Transaction.new(params[:transaction])
        @transaction.user = current_user
      end
    end

    if isPass
      @user
      point = params[:transaction][:point]
      account_name = params[:transaction][:account_name]
      if account_name.blank?
        @transaction.errors.add 'account_name', t('transaction.no_account_name')
        isPass = false
      else
        @user = User.where(:username => account_name).first
        if @user
          @transaction.account_id = @user.id
        else
          @transaction.errors.add 'account_name', t('transaction.not_account_name')
          isPass = false
        end
      end

      @transaction.trade_time = Time.now if @transaction.trade_time.nil?
    end

    respond_to do |format|
      Transaction.transaction do
        if isPass and @transaction.save
          if @user
            # 没有充值id, 则是发布点购买操作
            log_type = 'charge'
            if @transaction.point
              @user.account_credit = @user.account_credit + @transaction.point 
              log_type = "point"
            end
            @user.account_money = (@user.account_money + @transaction.amount) if point.blank?
            # 如果是批准充值, 则批准该申请
            unless session[:trade_id].blank?
              trade = Trade.find(session[:trade_id])
              trade.approve
              trade.save
              Accountlog.create! :user_id => @user.id, :user_name => @user.username, :operator_id => current_user.id, :operator_name => current_user.username, :trade_id => trade.id, :amount => trade.price, :log_type => 'charge', :description => t('trade.approve') + ' ' + t('account.point') + ":" + (@user.account_credit).to_s + "  " + I18n.t('account.account_money') + ":" + (@user.account_money).to_s
            end
            @user.save
            # 保存日志
            if session[:trade_id].blank?
              if log_type == 'point'
                Accountlog.create! :user_id => @user.id, :user_name => @user.username, :operator_id => current_user.id, :operator_name => current_user.username, :amount => @transaction.amount, :log_type => log_type, :description => t('trade.record') + ' ' + t('account.point') + ":" + (@user.account_credit).to_s + "  " + I18n.t('account.account_money') + ":" + (@user.account_money).to_s
              else
                Accountlog.create! :user_id => @user.id, :user_name => @user.username, :operator_id => current_user.id, :operator_name => current_user.username, :amount => @transaction.amount, :log_type => log_type, :description => t('trade.record') + ' ' + t('account.point') + ":" + (@user.account_credit).to_s + "  " + I18n.t('account.account_money') + ":" + (@user.account_money).to_s
              end
            end
          end
          format.html { redirect_to(@transaction, :notice => t('global.operate_success')) }
          format.xml  { render :xml => @transaction, :status => :created, :location => @transaction }
        else
          format.html { render :action => "new" }
          format.xml  { render :xml => @transaction.errors, :status => :unprocessable_entity }
        end
      end
    end
  end

  # PUT /transactions/1
  # PUT /transactions/1.xml
  def update
    session[:operate_mode] = nil
    @transaction = Transaction.find(params[:id])

    respond_to do |format|
      if @transaction.update_attributes(params[:transaction])
        format.html { redirect_to(@transaction, :notice => t('global.operate_success')) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @transaction.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /transactions/1
  # DELETE /transactions/1.xml
  def destroy
    @transaction = Transaction.find(params[:id])
    @transaction.destroy

    respond_to do |format|
      format.html { redirect_to(transactions_url) }
      format.xml  { head :ok }
    end
  end
end
