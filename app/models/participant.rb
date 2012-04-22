class Participant < ActiveRecord::Base
  belongs_to :user
  has_many :tasks

  validates_presence_of :part_id, :part_type, :role_type
  validates_uniqueness_of :part_id, :message => I18n.t('global.existed')
  validates_length_of :part_id, :within => 3..40
  #validates_format_of :url, :with => /^[A-Za-z]+:\/\/[A-Za-z0-9\-_]+\.[A-Za-z0-9\-_%&\?\/\.=]+$/, :message => 'http://... or https://...'

  # If not set, create new participant will failed
  # It need to test in further rails edition
  # 2012.4.22
  attr_accessible :part_id, :part_type, :role_type

  def make_active
    other = self.user.participants.where(:role_type => self.role_type, :active => true).first
    if other
      other.active = false
      other.save
    end
    self.active = true
    #return true if self.save
    #return false
  end

  state_machine :status, :initial => :active do
    event :warn do
      transition :active => :danger
    end
    event :free do
      transition :danger => :active
    end
    event :freeze do
      transition :active => :pause
    end
    event :unfreeze do
      transition :pause => :active
    end
    state :active, :value => 'active'
    state :danger, :value => 'danger'
    state :pause, :value => 'pause'
  end

  def local_status
    s = {'active' => I18n.t('participant.active'), 'danger' => I18n.t('participant.danger'), 'pause' => I18n.t('participant.pause')}
    return s[self.status]
  end

  # 该帐号下发布的任务数
  def own_tasks
    return Task.where(:shop => self.part_id)
  end

end
