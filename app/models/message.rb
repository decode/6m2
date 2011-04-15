class Message < ActiveRecord::Base
  belongs_to :user

  has_many :message_boxes, :dependent => :destroy
  has_many :receivers, :through => :message_boxes, :source => :user

  state_machine :status, :initial => :unread do
    event :make_read do
      transition :unread => :read
    end
    event :make_unread do
      transition :read => :unread
    end
    state :unread, :value => 'unread'
    state :read, :value => 'read'
  end
end
