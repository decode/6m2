# Fixe rails_admin bug:
# undefined local variable or method `per' for #<ActiveRecord::Relation:0xb1916fc>
# See https://github.com/mislav/will_paginate/issues/174
# 2012-04-19
if defined?(WillPaginate)
  module WillPaginate
    module ActiveRecord
      module RelationMethods
        def per(value = nil) per_page(value) end
        def total_count() count end
      end
    end
    module CollectionMethods
      alias_method :num_pages, :total_pages
    end
  end
end

#module WillPaginate  
  #class I18nRender < WillPaginate::ViewHelpers::LinkRenderer
    #def prepare(collection, options, template)  
      #options[:previous_label] = I18n.translate("site.previous")  
      #options[:next_label] = I18n.translate("site.next")  
      #super  
    #end  
  #end  
#end  

#WillPaginate::ViewHelpers.pagination_options[:renderer] = "WillPaginate::I18nRender"  

#require 'will_paginate'
#WillPaginate::ViewHelpers.pagination_options[:previous_label] = I18n.translate("site.previous")
#WillPaginate::ViewHelpers.pagination_options[:next_label] = I18n.translate("site.next")
