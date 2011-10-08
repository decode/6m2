class Accountlog < ActiveRecord::Base
  def local_type
    ltype = { 'charge' => I18n.t('trade.charge'), 'point' => I18n.t('trade.point'), 'recyling' => I18n.t('trade.recyling_point'), 'account' => I18n.t('site.personal_info'), 'credit' => I18n.t('account.credit'), 'point_penalty' => I18n.t('trade.point_penalty') }
    return ltype[self.log_type]
  end

  #def save_log(opt=>{})
    #user = opt[:user]
    #operator = opt[:operator]
    #log_type = opt[:log_type]
    #description = opt[:description]
    #point = opt[:point]
    #Accountlog.create! :user_id => user.id, :user_name => user.username, :operator_id => operator.id, :operator_name => operator.username, :amount => point, :log_type => log_type, :description => description
  #end
end
