class Issue < ActiveRecord::Base
  belongs_to :user
  belongs_to :dealer, :class_name=>'User', :foreign_key=>'dealer_id'
  has_many :penalties

  validates_length_of :title, :within => 4..30
  validates_length_of :content, :within => 0..160

  state_machine :status, :initial => :open do
    event :fix do
      transition :open => :done
    end
    event :shutdown do
      transition :open => :closed
    end
    state :open, :value => 'open'
    state :closed, :value => 'closed'
    state :done, :value => 'done'
  end

  def add_source(target)
    self.itype = target.class.name
    self.target_id = target.id
    #self.description = "#{target.class.name} User:#{target.user.username} Worker:#{target.worker.username}" if target.class.name == Task.name
  end

  def get_source
    return eval("#{self.itype}.find_by_id(#{self.target_id})") unless self.itype.nil? and self.target_id.nil?
  end
  
end
