class MessagesController < ApplicationController
  access_control do
    allow :superadmin, :admin, :manager, :user
    deny anonymous
  end

  # GET /messages
  # GET /messages.xml
  def index
    if current_user.has_role? 'admin'
      @messages = Message.order('created_at DESC').paginate(:page => params[:page], :per_page => 10)
    else
      @messages = current_user.received_messages.order('created_at DESC').paginate(:page => params[:page], :per_page => 10)
    end

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @messages }
    end
  end

  # GET /messages/1
  # GET /messages/1.xml
  def show
    @message = Message.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @message }
    end
  end

  # GET /messages/new
  # GET /messages/new.xml
  def new
    @message = Message.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @message }
    end
  end

  # GET /messages/1/edit
  def edit
    @message = Message.find(params[:id])
  end

  # POST /messages
  # POST /messages.xml
  def create
    @message = Message.new(params[:message])
    @message.user = current_user
    if session[:message_scale] == 'global'
      @message.msg_type = 'system' 
      User.find_each do |u|
        u.received_messages << @message
      end
      logger.info('==================================================' + @message.receivers.length.to_s) 
    end
    unless session[:message_to].nil? or session[:message_to] == ''
      user = User.find(session[:message_to])
      @message.msg_type = 'private'
      @message.receivers = user if user
    end

    respond_to do |format|
      if @message.save
        logger.info('==================================================' + @message.status.to_s) 
        format.html { redirect_to(messages_path, :notice => t('global.operate_success')) }
        format.xml  { render :xml => @message, :status => :created, :location => @message }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @message.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /messages/1
  # PUT /messages/1.xml
  def update
    @message = Message.find(params[:id])

    respond_to do |format|
      if @message.update_attributes(params[:message])
        format.html { redirect_to(@message, :notice => 'Message was successfully updated.') }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @message.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /messages/1
  # DELETE /messages/1.xml
  def destroy
    @message = Message.find(params[:id])
    @message.destroy

    respond_to do |format|
      format.html { redirect_to(messages_url) }
      format.xml  { head :ok }
    end
  end
end
