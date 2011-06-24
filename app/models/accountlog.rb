class Accountlog < ActiveRecord::Base
  def local_type
    ltype = { 'charge' => I18n.t('trade.charge'), 'point' => I18n.t('trade.point'), 'recyling' => I18n.t('trade.recyling_point'), 'account' => I18n.t('site.personal_info'), 'credit' => I18n.t('account.credit'), 'point_penalty' => I18n.t('trade.point_penalty') }
    return ltype[self.log_type]
  end
end
