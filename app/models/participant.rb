class Participant < ActiveRecord::Base
  belongs_to :user
  has_many :tasks

  def make_active
    return true if self.active == true
    other = self.user.participants.where(:active => true).first
    if other
      other.active = false
      other.save
    end
    self.active = true
    return true if self.save
    return false
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
      transaction :pause => :active
    end
    state :active, :value => 'active'
    state :danger, :value => 'danger'
    state :pause, :value => 'pause'
  end
  
end
