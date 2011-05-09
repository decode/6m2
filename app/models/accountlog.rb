class Accountlog < ActiveRecord::Base
  def local_type
    ltype = { 'charge' => I18n.t('trade.charge'), 'point' => I18n.t('trade.point'), 'recyling' => I18n.t('trade.recyling_point') }
    return ltype[self.log_type]
  end
end
