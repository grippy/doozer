module Paginate
  module ViewHelpers
    # default options that can be overridden on the global level
    @@pagination_options = {
      :class          => 'pagination',
      :previous_label => '&laquo; Previous',
      :next_label     => 'Next &raquo;',
      :inner_window   => 4, # links around the current page
      :outer_window   => 1, # links around beginning and end
      :separator      => ' ', # single space is friendly to spiders and non-graphic browsers
      :param_name     => :page,
      :params         => {},
      :page_links     => true,
      :container      => true,
      :debug          => false
    }
    mattr_reader :pagination_options

    def paginate(collection, options={})
      #Collection => :current_page, :per_page, :total_entries, :total_pages
      opt = @@pagination_options
      opt.update(options)
      out=[]
      if opt[:debug]
        out.push("current_page:#{collection.current_page} / ")
        out.push("per_page:#{collection.per_page} / ")
        out.push("total_entries:#{collection.total_entries} / ")
        out.push("total_pages:#{collection.total_pages} <br />")
      end
      out.push("<div class=\"pagination_container\">") if opt[:container]
      out.push(link(opt[:previous_label], {:page=>collection.previous_page}.update(opt[:params]), {:class=>opt[:class]}) ) if collection.previous_page
      out.push(link(opt[:next_label], {:page=>collection.next_page}.update(opt[:params]), {:class=>opt[:class]}) ) if collection.next_page
      out.push("</div>") if opt[:container]
      return out.join(opt[:separator])
    end
  end
end