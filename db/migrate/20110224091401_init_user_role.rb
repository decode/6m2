class InitUserRole < ActiveRecord::Migration
  def self.up
    user = User.create :username => 'superadmin', :password => '000000', :password_confirmation => '000000', :email => 'aero723@gmail.com' 
    user.has_role! 'super'
    user.has_role! 'admin'
    user.has_role! 'manager'
    user.has_role! 'user'
    user.has_no_role! 'guest'
    user.confirm!

    user = User.create :username => 'admin00', :password => '000000', :password_confirmation => '000000', :email => 'code723@gmail.com' 
    user.has_role! 'admin'
    user.has_role! 'manager'
    user.has_role! 'user'
    user.has_no_role! 'guest'
    user.confirm!
    test_init
  end

  def self.down
    users = User.all
    for u in users
      u.delete
    end
    roles = Role.all
    for r in roles
      r.delete
    end
  end

  def self.test_init
    user = User.create :username => 'administrator', :password => '000000', :password_confirmation => '000000', :email => 'yourname@gmail.com' 
    user.has_role! 'admin'
    user.has_role! 'manager'
    user.has_no_role! 'guest'
    user.confirm!
    user = User.create :username => 'manager', :password => '000000', :password_confirmation => '000000', :email => 'jjh@mail.com' 
    user.has_role! 'manager'
    user.has_no_role! 'guest'
    user.confirm!
    user = User.create :username => 'user00', :password => '000000', :password_confirmation => '000000', :email => 'user@mail.com' 
    user.has_role! 'user'
    user.has_no_role! 'guest'
    user.confirm!
    user = User.create :username => 'guest00', :password => '000000', :password_confirmation => '000000', :email => 'guest00@mail.com', :account_credit => 1000, :account_money => 1000, :payment_money => 1000 
    user.has_role! 'user'
    user.has_no_role! 'guest'
    user.confirm!
    user = User.create :username => 'sales00', :password => '000000', :password_confirmation => '000000', :email => 'sales00@mail.com', :account_credit => 1000, :account_money => 1000, :payment_money => 1000 
    user.has_role! 'sales'
    user.has_no_role! 'guest'
    user.confirm!
    user = User.create :username => 'guest01', :password => '000000', :password_confirmation => '000000', :email => 'guest01@mail.com' 
    user.has_role! 'user'
    user.has_no_role! 'guest'
    user.confirm!
  end
  
end
