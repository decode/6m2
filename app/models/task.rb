class Task < ActiveRecord::Base
  belongs_to :user
  belongs_to :worker, :class_name => 'User', :foreign_key => 'worker_id'
  belongs_to :supervisor, :class_name => 'User', :foreign_key => 'supervisor_id'
  belongs_to :transport
  belongs_to :participant

  validates_presence_of :title, :link, :price, :worker_level, :task_day, :avoid_day#, :task_level
  validates_numericality_of :price, :task_day, :greater_than => 0
  validates_numericality_of :avoid_day, :worker_level, :greater_than_or_equal_to => 0
  #validates_numericality_of :task_level
  validates_inclusion_of :task_type, :in => %w(taobao paipai youa virtual cash), :message => "%{value} is not a valid type"
  #validates_format_of :link, :with => /http[s]:\/\/*.*/, :message => "http://xxxx.xxx or https://xxxx.xxx"
  validates_format_of :link, :with => /^[A-Za-z]+:\/\/[A-Za-z0-9\-_]+\.[A-Za-z0-9\-_%&\?\/\.=]+$/, :message => 'http://... or https://...'

  validates_length_of :title, :within => 5..40
  validates_length_of :description, :within => 0..120

  #validate :low_point_cannot_make_task
  def low_point_cannot_make_task
    app = ApplicationController.new
    point = app.caculate_point(self)
    errors.add(:price) if self.price.nil?
    price = self.price.nil? ? 0 : self.price
    errors.add(:price, "not enough") if
      self.user.account_credit < point or self.user.account_money < price
  end

  after_save :log_save
  before_destroy :log_destroy
  def log_save
    log = Tasklog.new
    log.task_id = self.id
    log.user_id = self.user.id
    log.worker_id = self.worker.id if self.worker
    log.price = self.price
    log.point = self.point
    log.status = self.status
    log.save!
  end
  def log_destroy
    log = Tasklog.new
    log.task_id = self.id
    log.user_id = self.user.id if self.user
    log.worker_id = self.worker.id if self.worker
    log.price = self.price
    log.point = self.point
    log.status = self.status
    log.description = 'destroy'
    log.save!
  end

  state_machine :status, :initial => :unpublish do
    event :publish do
      transition :unpublished => :published
    end
    event :unpublish do
      transition :published => :unpublish
    end
    # 买方接手
    event :takeover do
      transition :published => :running
    end
    
    # =================================
    event :pay do
      transition :running => :cash
    end
    # 卖方发货
    event :send_good do
      transition :running => :transport
    end
    # 买方收货
    event :receive_good do
      transition :transport => :received
    end
    # 卖方收到货款
    event :receive_money do
      transition :received => :money
    end
    # =================================
    
    # 买方好评
    event :finish do
      #transition :money => :finished
      transition :cash => :finished
      #transition :running => :finished
    end
    # 卖方结束该流程
    event :over do
      transition [:finished, :problem] => :end
    end
    event :argue do
      transition [:finished, :running] => :problem
    end
    event :giveup do
      transition :running => :abandon
    end
    state :unpublished, :value => 'unpublished'
    state :published, :value => 'published'
    state :running, :value => 'running'
    state :cash, :value => 'cash'
    #state :transport, :value => 'transport'
    #state :received, :value => 'received'
    #state :money, :value => 'money'
    state :pending, :value => 'pending'
    state :abandon, :value => 'abandon'
    state :finished, :value => 'finished'
    state :problem, :value => 'problem'
    state :end, :value => 'end'
  end

  def local_status
    lang = {'unpublished' => I18n.t('task.unpublished'), 'published' => I18n.t('task.published'), 'running' => I18n.t('task.running'), 'cash' => I18n.t('task.payed'), 'finished' => I18n.t('task.finished'), 'problem' => I18n.t('task.problem'), 'end' => I18n.t('task.end')}
    return lang[self.status]
  end

  def can_modify?
    return (self.published? || self.unpublished?)
  end

  def free_task?
    return self.task_type == 'cash'
  end
  
  def can_do?(user)
    error = ''
    # 不能接自己创建的任务
    c = (self.user != user)
    unless c
      error = error + t('task.error_self') 
      return [false,error]
    end
    # 小号必须定义
    c0 = !user.active_participant.nil?
    unless c0
      error = error + ' ' + I18n.t('task.error_buyer') 
      return [false,error]
    end
    # manager权限或不低于指定级别
    c1 = (user.has_role?('manager') or user.level >= self.worker_level)
    unless c1
      error = error + ' ' + I18n.t('task.error_level') 
      logger.info("======================#{user.level} #{self.worker_level}============================")
      return [false,error]
    end
    # 发任务方限制天数内不能接任务
    c2 = user.todos.where(:finished_time => (self.created_at-self.avoid_day.day) .. self.created_at, :user_id => self.user.id).length == 0
    unless c2
      error = error + ' ' + I18n.t('task.error_avoidday') 
      return [false,error]
    end
    # 每个买号每日最多接手6个任务
    c3 = user.active_participant.tasks.where(:takeover_time => (Time.now-1.days)..Time.now, :participant_id => user.active_participant.id).length <= 6
    unless c3
      error = error + ' ' + I18n.t('task.error_day') 
      return [false,error]
    end
    # 每周最多接手35个任务
    c4 = user.active_participant.tasks.where(:takeover_time => (Time.now-7.days)..Time.now, :participant_id => user.active_participant.id).length <= 35 
    unless c4
      error = error + ' ' +  I18n.t('task.error_month') 
      return [false,error]
    end
    # 同一买号不能在一个自然月内接同一发布人同一网店任务超过六个
    c5 = user.active_participant.tasks.where(:takeover_time => (Time.now-30.days)..Time.now, :participant_id => user.active_participant.id, :user_id => self.user.id).length <= 6
    unless c5
      error = error + ' ' + I18n.t('task.error_sameshop') 
      return [false,error]
    end

    #logger.info("C1:" + c1.to_s + " C2:" + c2.to_s + " C3:" + c3.to_s + " C4:" + c4.to_s + " C5:" + c5.to_s)

    #return (c0 and c1 and c2 and c3 and c4 and c5) ? [true, ''] : [false, error]
    return [true, '']
  end

end
