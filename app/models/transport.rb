class Transport < ActiveRecord::Base
  has_many :tasks

  has_many :user_transports, :dependent => :destroy
  has_many :users, :through => :user_transports

  state_machine :status, :initial => :unchecked do
    event :check do
      transition :unchecked => :used
    end
    event :close do
      transition :used => :closed
    end
    event :reuse do
      transition :closed => :used
    end
    state :unchecked, :value => 'unchecked'
    state :used, :value => 'used'
    state :closed, :value => 'closed'
  end
end
