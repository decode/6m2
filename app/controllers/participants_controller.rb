class ParticipantsController < ApplicationController
  access_control do
    allow :admin, :manager
    allow :user, :guest, :except => [:edit, :update]
    deny anonymous
  end

  # GET /participants
  # GET /participants.xml
  def index
    @participants = current_user.participants.where("role_type = 'customer'").order("created_at DESC").paginate(:page => params[:page], :per_page => 10)
    @shops = current_user.participants.where("role_type = 'shop'").order("created_at DESC").paginate(:page => params[:page], :per_page => 10)

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @participants }
    end
  end

  # GET /participants/1
  # GET /participants/1.xml
  def show
    @participant = Participant.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @participant }
    end
  end

  # GET /participants/new
  # GET /participants/new.xml
  def new
    session[:operate_mode] = nil
    @participant = Participant.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @participant }
    end
  end

  # GET /participants/1/edit
  def edit
    @participant = Participant.find(params[:id])
    session[:operate_mode] = 'edit'
  end

  # POST /participants
  # POST /participants.xml
  def create
    @participant = Participant.new(params[:participant])
    isPass = true
    if params[:participant][:role_type] == 'shop' 
      if params[:participant][:url].blank?
        @participant.errors.add 'url', t('participant.no_shop_url')
      else
        @participant.errors.add 'url', t('participant.shop_existed') if Participant.where('url = ?', params[:participant][:url]).length > 0
      end
      isPass = false
    end
    @participant.user = current_user
    if (@participant.role_type == 'shop' and current_user.active_shop.nil?) or (@participant.role_type == 'customer' and current_user.active_participant.nil?)
      @participant.active = true 
    else
      @participant.make_active if params[:participant][:active] == '1'
    end
    isFirst = false
    if current_user.has_role? 'guest' and current_user.active_participant.length == 0
      isFirst = true
    end

    logger.info('======================='+isPass.to_s)

    respond_to do |format|
      Participant.transaction do
        if isPass and @participant.save
          # 绑定买号以后自动转为user权限
          if isFirst
            current_user.has_no_role! 'guest'
            current_user.has_role! 'user'
          end
          format.html { redirect_to(participants_path, :notice => t('global.operate_success')) }
          format.xml  { render :xml => @participant, :status => :created, :location => @participant }
        else
          format.html { render :action => "new" }
          format.xml  { render :xml => @participant.errors, :status => :unprocessable_entity }
        end
      end
    end
  end

  # PUT /participants/1
  # PUT /participants/1.xml
  def update
    @participant = Participant.find(params[:id])
    if params[:participant][:active] == '1'
      @participant.make_active
    end

    respond_to do |format|
      if @participant.update_attributes(params[:participant])
        session[:operate_mode] = nil
        format.html { redirect_to(@participant, :notice => t('global.operate_success')) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @participant.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /participants/1
  # DELETE /participants/1.xml
  def destroy
    @participant = Participant.find(params[:id])
    @participant.destroy

    respond_to do |format|
      format.html { redirect_to :back }
      format.xml  { head :ok }
    end
  end
end
