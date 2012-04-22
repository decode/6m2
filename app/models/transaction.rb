class Transaction < ActiveRecord::Base
  belongs_to :user
  belongs_to :sales, :class_name => 'User', :foreign_key => 'sales_id'

  validates_uniqueness_of :tid
  validates_presence_of :tid, :amount, :trade_time, :account_name
  validates_numericality_of :amount, :greater_than => 0

  # add after rails 3.1
  attr_accessible :tid, :bank, :name, :pay_type, :amount, :account_name, :trade_time, :trade_time, :trade_time, :trade_time, :trade_time, :description

  def local_pay_type
    s = {'zfb'=>I18n.t('trade.zfb'), 'cft'=>I18n.t('trade.cft'), 'wy'=>I18n.t('trade.wy')}
    return s[self.pay_type]
  end
  
end
