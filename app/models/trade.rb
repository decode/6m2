class Trade < ActiveRecord::Base
  belongs_to :user
  belongs_to :receiced_user, :class_name => 'User', :foreign_key => 'to_id'

  state_machine :status, :initial => :request do
    event :approve do
      transition :request => :approved
    end
    event :reject do
      transition :request => :rejected
    end
    state :request, :value => 'request'
    state :rejected, :value => 'rejected'
    state :approved, :value => 'approved'
  end
end
