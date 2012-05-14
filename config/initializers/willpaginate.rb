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
    # fix bugs for will_paginage and bootstrap
    module ActionView
      def will_paginate(collection = nil, options = {})
        options[:renderer] ||= BootstrapLinkRenderer
        super.try :html_safe
      end

      class BootstrapLinkRenderer < LinkRenderer
        protected

        def html_container(html)
          tag :div, tag(:ul, html), container_attributes
        end

        def page_number(page)
          tag :li, link(page, page, :rel => rel_value(page)), :class => ('active' if page == current_page)
        end

        def previous_or_next_page(page, text, classname)
          tag :li, link(text, page || '#'), :class => [classname[0..3], classname, ('disabled' unless page)].join(' ')
        end

        def gap
          tag :li, link(super, '#'), :class => 'disabled'
        end
      end
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
