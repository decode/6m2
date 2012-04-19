# coding: utf-8
module ApplicationHelper

  # acl9 configuration
  include Acl9Helpers
  access_control :superadmin? do
    allow :superadmin
  end
  access_control :admin? do
    allow :admin, :super
  end
  access_control :manager? do
    allow :manager
  end
  access_control :salesman? do
    allow :salesman
  end
  access_control :user? do
    allow :user
  end
  access_control :guest? do
    allow :guest
  end
  

  def convert_tran_type(tran_type)
    unless tran_type.nil? or tran_type == ''
      tran = %w{ 圆通 申通 中通 韵达 顺丰 EMS } 
      abb = %w{ yt st zt yd sf ems }
      return tran[abb.index(tran_type)]
    end
    return ''
  end

  def convert_yes_no(condition)
    return condition ? I18n.t('global.isyes') : I18n.t('global.isno')
  end

  def convert_shop_type(shop)
    return image_tag("#{shop}.png")
  end

  def trade_type_image(trade_type)
    return image_tag("#{trade_type}.png")
  end
    
end
