class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :token_authenticatable, :confirmable, :lockable and :timeoutable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable, :token_authenticatable, :confirmable, :lockable, :timeoutable

  # Setup accessible (or protected) attributes for your model
  attr_accessible :username, :email, :password, :password_confirmation, :remember_me

  attr_accessor :login
  attr_accessible :login, :account_credit

  # Acl9 configuration
  acts_as_authorization_subject
  
  validates_uniqueness_of :username

  has_many :tasks
  has_many :todos, :class_name => 'Task', :foreign_key => 'worker_id'
  has_many :managed_tasks, :class_name => 'Task', :foreign_key => 'supervisor_id'
  has_many :trades
  has_many :received_trades, :class_name => 'Trade', :foreign_key =>'to_id'
  has_many :issues
  has_many :deal_issues, :class_name => 'Issue', :foreign_key => 'dealer_id'
  has_many :penalties

  #validates_presence_of :bank_account, :im_q

  state_machine :status, :initial => :normal do
    event :suspend do
      transition :normal => :forbid
    end
    event :kill do
      transition [:normal, :forbid] => :ban
    end
    event :release do
      transition [:forbid, :ban] => :normal
    end
    state :normal, :value => 'normal'
    state :forbid, :value => 'forbid'
    state :ban, :value => 'ban'
  end

  def level
    @set = Setting.first
    @level = [@set.class1, 
      @set.class2, 
      @set.class3, 
      @set.class4, 
      @set.class5, 
      self.score].sort.index(self.score)
    return @level
  end

  def status_tasks(status)
    return self.tasks.where('status = ?', status) 
  end
  
  
  protected

  def self.find_for_database_authentication(conditions)
    login = conditions.delete(:login)
    where(conditions).where(["username = :value OR email = :value", { :value => login }]).first
  end

end
