class SiteController < ApplicationController
  def index
    @notice = Notice.last #order("created_at Desc").limit(5)
    @setting = Setting.first
    @running_count = @setting.running_task + Task.all.length
    @user_count = @setting.total_user + User.all.length
    @user = current_user

    #role = Role.where(:name => 'admin').first
    #ids = role.user_ids.drop(1)
    #@customers = User.where(:id => ids).where('im_q is not null').order("created_at DESC")#.paginate(:page => params[:page], :per_page => 20)
    #role = Role.where(:name => 'admin').first
    #ids = role.user_ids.drop(1)
    #@admins = User.where(:id => ids).order("created_at DESC")#.paginate(:page => params[:page], :per_page => 20)

    @users = User.where("username != 'superadmin'").order("created_at Desc").limit(5)
    #offs = rand(Article.count)
    @articles = Article.where("article_type = 'wiki'").order("created_at DESC").limit(9)#.offset(offs)
    @rules = Article.where("article_type = 'rule'").order("created_at DESC").limit(9)#.offset(offs)
  end

  def setting
    @setting = Setting.first  
  end

  def update_setting
    @setting = Setting.find(params[:id])
    if @setting.update_attributes(params[:setting])
      flash[:notice] = t('global.update_success')
    else
      flash[:notice] = t('global.update_failed')
    end
    redirect_to '/'
  end
  
  # 发送系统消息
  def message
    session[:message_scale] = 'global'
    redirect_to new_message_url
  end
  
end
