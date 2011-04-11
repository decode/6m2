# coding: utf-8
module ApplicationHelper
  def convert_tran_type(tran_type)
    unless tran_type.nil? or tran_type == ''
      tran = %w{ 圆通 申通 中通 韵达 顺丰 EMS } 
      abb = %w{ yt st zt yd sf ems }
      return tran[abb.index(tran_type)]
    end
    return ''
  end
  
end
