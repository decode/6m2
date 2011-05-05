class TransactionsController < ApplicationController
  access_control do
    allow :admin, :manager, :sales
    #allow :sales, :except => [:edit, :update, :destroy]
    deny anonymous
  end

  # GET /transactions
  # GET /transactions.xml
  def index
    if current_user.has_role? 'admin'
      @transactions = Transaction.order('created_at DESC').paginate(:page => params[:page], :per_page => 20)
      session[:transaction_mode] = nil
    else
      @transactions = Transaction.find('sales_id = ?', current_user.id).order('created_at DESC').paginate(:page => params[:page], :per_page => 20)
      session[:transaction_mode] = 'sales'
    end

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

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @transaction }
    end
  end

  # GET /transactions/1/edit
  def edit
    @transaction = Transaction.find(params[:id])
  end

  # POST /transactions
  # POST /transactions.xml
  def create
    @transaction = Transaction.new(params[:transaction])
    isPass = true
    if session[:transaction_mode] == 'sales'
      @transaction = Transaction.find('tid = ?', @transaction.tid).first
      if tran
        @transaction.sales = current_user
      else 
        @transaction.errors.add(t('transaction.no_tid'), 'tid')
        @transaction.errors.add(t('transaction.has_sales'), 'tid') if @transaction.sales.nil?
        isPass = false 
      end
    end

    respond_to do |format|
      if isPass and @transaction.save
        format.html { redirect_to(@transaction, :notice => t('global.operate_success')) }
        format.xml  { render :xml => @transaction, :status => :created, :location => @transaction }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @transaction.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /transactions/1
  # PUT /transactions/1.xml
  def update
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
