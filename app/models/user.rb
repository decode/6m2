class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :token_authenticatable, :confirmable, :lockable and :timeoutable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable, :token_authenticatable, :confirmable, :lockable, :timeoutable

  # Setup accessible (or protected) attributes for your model
  attr_accessible :username, :email, :password, :password_confirmation, :remember_me

  attr_accessor :login
  attr_accessible :login, :account_credit
  attr_accessible :role_object_ids, :score
  attr_accessible :im, :im_q, :bank_name, :bank_account, :mobile, :person_id, :shop_taobao, :shop_taobao_url, :shop_paipai, :shop_paipai_url, :shop_youa, :shop_youa_url

  # Acl9 configuration
  acts_as_authorization_subject
  
  validates_uniqueness_of :username
  validates_length_of :username, :within => 6..12
  #validates_length_of :im_q, :within => 0..20
  #validates_length_of :im, :within => 0..40
  #validates_length_of :bank_name, :bank_account, :mobile, :person_id, :shop_taobao, :shop_taobao_url, :shop_paipai, :shop_paipai_url, :shop_youa, :shop_youa_url, :within => 0..160

  has_many :tasks, :dependent => :destroy
  has_many :todos, :class_name => 'Task', :foreign_key => 'worker_id'
  has_many :managed_tasks, :class_name => 'Task', :foreign_key => 'supervisor_id'
  has_many :trades
  has_many :received_trades, :class_name => 'Trade', :foreign_key =>'to_id'
  has_many :issues
  has_many :deal_issues, :class_name => 'Issue', :foreign_key => 'dealer_id'
  has_many :penalties

  has_many :user_transports
  has_many :transports, :through => :user_transports

  has_many :participants

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

  def active_participant
    return self.participants.where('active = true').first
  end
  
  
  protected

  def self.find_for_database_authentication(conditions)
    login = conditions.delete(:login)
    where(conditions).where(["username = :value OR email = :value", { :value => login }]).first
  end

end
