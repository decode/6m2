class MessageBox < ActiveRecord::Base
  belongs_to :user
  belongs_to :message

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

  def local_status
    s = {'unread' => I18n.t('message.unread'), 'read' => I18n.t('message.read')}
    return s[self.status]
  end
end
