class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :token_authenticatable, :confirmable, :lockable and :timeoutable
  devise :database_authenticatable, :registerable, :recoverable, :rememberable, :trackable, :validatable, :token_authenticatable, :confirmable, :lockable, :timeoutable
  devise :stretches => 10
  devise :authentication_keys => [:login]

  # Setup accessible (or protected) attributes for your model
  attr_accessible :username, :email, :password, :password_confirmation, :remember_me

  attr_accessor :login
  attr_accessible :login, :account_credit
  attr_accessible :role_object_ids, :score, :operate_password, :status
  attr_accessible :im, :im_q, :bank_name, :bank_account, :mobile, :person_id, :shop_taobao, :shop_taobao_url, :shop_paipai, :shop_paipai_url, :shop_youa, :shop_youa_url

  # Acl9 configuration
  acts_as_authorization_subject :association_name => :roles, :join_table_name => :roles_users
  
  validates_uniqueness_of :username
  validates_length_of :username, :within => 6..20
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

  has_many :messages

  has_many :message_boxes
  has_many :received_messages, :through => :message_boxes, :source => :message

  has_many :articles

  has_many :transactions
  has_many :business, :class_name => 'Transaction', :foreign_key => 'sales_id'

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

  after_create :log_create
  before_destroy :log_destroy
  def log_create
    Accountlog.create! :user_id => self.id, :log_type => 'account', :description => self.username + I18n.t("account.create_account")
  end
  
  def log_destroy
    Accountlog.create! :user_id => self.id, :log_type => 'account', :description => self.username + I18n.t("account.delete_account")
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

  def status_todos(status)
    return self.todos.where('status = ?', status) 
  end

  def active_participant
    return self.participants.where("role_type = 'customer' and active = ?", true).first
  end
  
  def active_shop
    return self.participants.where("role_type = 'shop' and active = ?", true).first
  end

  def shops
    return self.participants.where("role_type = 'shop'")
  end

  def shop_limit
    limit = [1,2,3,4,5,6]
    step = [500, 1000, 2000, 5000, 10000]
    index = step.select{ |s| s < self.account_credit }.length
    number = limit[index]
    return number
  end

  def can_create_shop?
    return self.shops.length < self.shop_limit
  end

  def own_transactions
    Transaction.where(:account_name => self.username)
  end
  
  #def save_log(user, money=0, point=0, log_type='charge', operator=nil, description=nil)
    #alog = Accountlog.new
    #alog.user_id = user.id
    #alog.user_name = user.username
    #alog.operator_id = operator.id
    #alog.operator_name = operator.username
    #alog.trade_id = trade.id
    #alog.account_money = money
    #alog.account_credit = point
    #alog.log_type = 'charge'
    #alog.description = description
    #alog.save
  #end
  
  protected
  #def self.find_for_database_authentication(conditions)
    #login = conditions.delete(:login)
    #where(conditions).where(["username = :value OR email = :value", { :value => login }]).first
  #end

  # For devise support username or email
  def self.find_for_database_authentication(warden_conditions)
    conditions = warden_conditions.dup
    login = conditions.delete(:login)
    where(conditions).where(["lower(username) = :value OR lower(email) = :value", { :value => login.strip.downcase }]).first
  end

end
