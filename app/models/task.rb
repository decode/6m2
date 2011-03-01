class Task < ActiveRecord::Base
  belongs_to :user
  belongs_to :worker, :class_name => 'User', :foreign_key => 'worker_id'
  belongs_to :supervisor, :class_name => 'User', :foreign_key => 'supervisor_id'


  validates_presence_of :title, :link, :price, :worker_level, :task_day, :avoid_day, :task_level
  validates_numericality_of :price, :worker_level, :task_day, :avoid_day, :greater_than => 0
  validates_numericality_of :task_level
  validates_inclusion_of :task_type, :in => %w(taobao paipai youa cash), :message => "%{value} is not a valid type"
  #validates_format_of :link, :with => /http[s]:\/\/*.*/, :message => "http://xxxx.xxx or https://xxxx.xxx"
  validates_format_of :link, :with => /^[A-Za-z]+:\/\/[A-Za-z0-9-_]+\.[A-Za-z0-9-_%&\?\/\.=]+$/, :message => 'http://... or https://...'

  validate :low_point_cannot_make_task
 
  def low_point_cannot_make_task
    point = caculate_point(self)
    errors.add(:price) if self.price.nil?
    price = self.price.nil? ? 0 : self.price
    errors.add(:price, "not enough") if
      self.user.account_credit < point and self.user.account_money < price
  end

  #def caculate_point(task)
  #  point = task.task_level + task.avoid_day + task.task_day + task.worker_level
  #  point = point + 1 if task.extra_word
  #  return point
  #end

  after_save :log_save
  before_destroy :log_destroy
  def log_save
    log = Tasklog.new
    log.task_id = self.id
    log.user_id = self.user.id
    log.worker_id = self.worker.id if self.worker
    log.price = self.price
    log.status = self.status
    log.save!
  end
  def log_destroy
    log = Tasklog.new
    log.task_id = self.id
    log.user_id = self.user.id
    log.worker_id = self.worker.id if self.worker
    log.price = self.price
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
    event :takeover do
      transition :published => :running
    end
    event :finish do
      transition :running => :finished
    end
    event :argue do
      transition [:finished, :running] => :problem
    end
    event :over do
      transition [:finished, :problem] => :end
    end
    event :giveup do
      transition :running => :abandon
    end
    state :unpublished, :value => 'unpublished'
    state :published, :value => 'published'
    state :running, :value => 'running'
    state :pending, :value => 'pending'
    state :abandon, :value => 'abandon'
    state :finished, :value => 'finished'
    state :problem, :value => 'problem'
    state :end, :value => 'end'
  end

  def can_modify?
    #return ['unpublished', 'published'].include? self.status
    return (self.published? or self.unpublished?)
  end

  def free_task?
    return self.task_type == 'cash'
  end
  

  #def initialize
  #  super()
  #end

end
