class TransportsController < ApplicationController
  # GET /transports
  # GET /transports.xml
  def index
    @transports = Transport.all

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @transports }
    end
  end

  # GET /transports/1
  # GET /transports/1.xml
  def show
    @transport = Transport.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @transport }
    end
  end

  # GET /transports/new
  # GET /transports/new.xml
  def new
    @transport = Transport.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @transport }
    end
  end

  # GET /transports/1/edit
  def edit
    @transport = Transport.find(params[:id])
  end

  # POST /transports
  # POST /transports.xml
  def create
    @transport = Transport.new(params[:transport])

    respond_to do |format|
      if @transport.save
        format.html { redirect_to(@transport, :notice => 'Transport was successfully created.') }
        format.xml  { render :xml => @transport, :status => :created, :location => @transport }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @transport.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /transports/1
  # PUT /transports/1.xml
  def update
    @transport = Transport.find(params[:id])

    respond_to do |format|
      if @transport.update_attributes(params[:transport])
        format.html { redirect_to(@transport, :notice => 'Transport was successfully updated.') }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @transport.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /transports/1
  # DELETE /transports/1.xml
  def destroy
    @transport = Transport.find(params[:id])
    @transport.destroy

    respond_to do |format|
      format.html { redirect_to(transports_url) }
      format.xml  { head :ok }
    end
  end
end
