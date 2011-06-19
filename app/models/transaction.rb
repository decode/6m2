class Transaction < ActiveRecord::Base
  belongs_to :user
  belongs_to :sales, :class_name => 'User', :foreign_key => 'sales_id'

  validates_uniqueness_of :tid
  validates_presence_of :tid, :amount, :trade_time, :account_name
  validates_numericality_of :amount, :greater_than => 0
end
