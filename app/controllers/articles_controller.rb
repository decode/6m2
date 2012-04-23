class ArticlesController < ApplicationController
  include TinymceFilemanager
  #layout 'article'
  access_control do
    allow :admin, :manager, :user
    allow :user, :except => [:new, :edit, :create, :update, :destroy]
    deny anonymous
  end

  #uses_tiny_mce :options => {
  #                            :theme => 'advanced',
  #                            :theme_advanced_resizing => true,
  #                            :theme_advanced_resize_horizontal => true,
  #                            :plugins => %w{ table fullscreen }
  #                          }

  # GET /articles
  # GET /articles.xml
  def index
    if current_user.has_role? 'admin'
      @articles = Article.order('created_at DESC').paginate(:page => params[:page], :per_page => 20)
    else
      @articles = Article.where("article_type = 'rule'").order('created_at DESC').paginate(:page => params[:page], :per_page => 20)
    end

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @articles }
    end
  end

  # GET /articles/1
  # GET /articles/1.xml
  def show
    @article = Article.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @article }
    end
  end

  # GET /articles/new
  # GET /articles/new.xml
  def new
    @article = Article.new
    @article.article_type = 'wiki'

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @article }
    end
  end

  # GET /articles/1/edit
  def edit
    @article = Article.find(params[:id])
  end

  # POST /articles
  # POST /articles.xml
  def create
    @article = Article.new(params[:article])
    @article.user = current_user
    @article.article_type = 'wiki' if @article.article_type.blank?

    respond_to do |format|
      if @article.save
        format.html { redirect_to(@article, :notice => t('global.operate_success')) }
        format.xml  { render :xml => @article, :status => :created, :location => @article }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @article.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /articles/1
  # PUT /articles/1.xml
  def update
    @article = Article.find(params[:id])

    respond_to do |format|
      if @article.update_attributes(params[:article])
        format.html { redirect_to(@article, :notice => t('global.operate_success')) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @article.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /articles/1
  # DELETE /articles/1.xml
  def destroy
    @article = Article.find(params[:id])
    @article.destroy

    respond_to do |format|
      format.html { redirect_to(articles_url) }
      format.xml  { head :ok }
    end
  end
end
