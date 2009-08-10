module Paginate

  class InvalidPage < ArgumentError
    def initialize(page, page_num)
      super "#{page.inspect} given as value, which translates to '#{page_num}' as page number"
    end
  end
  
  class Collection < Array
    attr_reader :current_page, :per_page, :total_entries, :total_pages

    def initialize(page, per_page, total = nil)
      @current_page = page.to_i
      raise InvalidPage.new(page, @current_page) if @current_page < 1
      @per_page = per_page.to_i
      raise ArgumentError, "`per_page` setting cannot be less than 1 (#{@per_page} given)" if @per_page < 1
      
      self.total_entries = total if total
    end

    def self.create(page, per_page, total = nil)
      pager = new(page, per_page, total)
      yield pager
      pager
    end

    def out_of_bounds?
      current_page > total_pages
    end

    def offset
      (current_page - 1) * per_page
    end

    def previous_page
      current_page > 1 ? (current_page - 1) : nil
    end

    def next_page
      current_page < total_pages ? (current_page + 1) : nil
    end
    
    def total_entries=(number)
      @total_entries = number.to_i
      @total_pages   = (@total_entries / per_page.to_f).ceil
    end

    def replace(array)
      result = super
      
      # The collection is shorter then page limit? Rejoice, because
      # then we know that we are on the last page!
      if total_entries.nil? and length < per_page and (current_page == 1 or length > 0)
        self.total_entries = offset + length
      end

      result
    end
  end
end
