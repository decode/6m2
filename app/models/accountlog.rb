class Accountlog < ActiveRecord::Base
  def local_type
    ltype = { 'charge' => I18n.t('trade.charge'), 'point' => I18n.t('trade.point'), 'recyling' => I18n.t('trade.recyling_point'), 'account' => I18n.t('site.personal_info'), 'credit' => I18n.t('account.credit'), 'point_penalty' => I18n.t('trade.point_penalty') }
    return ltype[self.log_type]
  end

  #def save_log(:user, :money=>0, :point=>0, :log_type=>'charge', :operator=>nil, :description=>nil)
    #alog = Accountlog.new
    #alog.user_id = :user.id
    #alog.user_name = :user.username
    #alog.operator_id = :operator.id
    #alog.operator_name = :operator.username
    #alog.trade_id = :trade.id
    #alog.account_money = :money
    #alog.account_credit = :point
    #alog.log_type = 'charge'
    #alog.description = :description
    #alog.save
  #end
end
