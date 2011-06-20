class Tasklog < ActiveRecord::Base
  def local_status
    lang = {'unpublished' => I18n.t('task.unpublished'), 'published' => I18n.t('task.published'), 'running' => I18n.t('task.do'), 'price' => I18n.t('task.price'), 'cash' => I18n.t('task.pay'), 'finished' => I18n.t('task.finish'), 'problem' => I18n.t('task.problem'), 'end' => I18n.t('task.confirm'), 'transport' => I18n.t('task.transport')}
    return lang[self.status]
  end
end
