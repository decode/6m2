class Transport < ActiveRecord::Base
  has_many :tasks

  state_machine :status, :initial => :unused do
    event :use do
      transition :unused => :used
    end
    event :close do
      transition :used => :closed
    end
    event :reuse do
      transition :closed => :used
    end
    state :unused, :value => 'unused'
    state :used, :value => 'used'
    state :closed, :value => 'closed'
  end
end
