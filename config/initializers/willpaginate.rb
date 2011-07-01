module WillPaginate  
  class I18nRender < WillPaginate::ViewHelpers::LinkRenderer
    def prepare(collection, options, template)  
      options[:previous_label] = I18n.translate("site.previous")  
      options[:next_label] = I18n.translate("site.next")  
      super  
    end  
  end  
end  

WillPaginate::ViewHelpers.pagination_options[:renderer] = "WillPaginate::I18nRender"  

#require 'will_paginate'
#WillPaginate::ViewHelpers.pagination_options[:previous_label] = I18n.translate("site.previous")
#WillPaginate::ViewHelpers.pagination_options[:next_label] = I18n.translate("site.next")
