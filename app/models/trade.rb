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

  def local_status
    lstatus = {'request' => I18n.t('trade.request'), 'rejected' => I18n.t('trade.reject'), 'approved' => I18n.t('trade.approve')}
    return lstatus[self.status]
  end
  
  def local_type
    ltype = {'charge' => I18n.t('trade.charge'), 'point' => I18n.t('trade.point'), 'recyling' => I18n.t('trade.recyling_point'), 'score' => I18n.t('trade.score_point')}
    return ltype[self.trade_type]
  end

end
