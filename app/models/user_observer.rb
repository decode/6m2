class UserObserver < ActiveRecord::Observer
  def after_create(user)
    user.has_role! 'guest'
  end
  
end
