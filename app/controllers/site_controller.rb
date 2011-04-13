class SiteController < ApplicationController
  def index
    @notices = Notice.order("created_at Desc").limit(5)
    @running_count = Task.where("status = 'published'").length
    @user_count = User.all.length
    @user = current_user
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
    redirect_to new_message_url#(current_user)
  end
  
end
