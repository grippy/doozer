module Paginate
  module Finder
  
    def self.included(base)
      base.extend ClassMethods
      class << base
        # alias_method_chain :method_missing, :paginate
        # # alias_method_chain :find_every,     :paginate
        define_method(:per_page) { 30 } unless respond_to?(:per_page)
      end
    end

    module ClassMethods

      def paginate(*args)
        options = args.pop
        page, per_page, total_entries = paginate_parse_options(options)

        finder = (options[:finder] || 'find').to_s

        if finder == 'find'
          # an array of IDs may have been given:
          total_entries ||= (Array === args.first and args.first.size)
          # :all is implicit
          args.unshift(:all) if args.empty?
        end

        Paginate::Collection.create(page, per_page, total_entries) do |pager|
          count_options = options.except :page, :per_page, :total_entries, :finder
          find_options = count_options.except(:count).update(:offset => pager.offset, :limit => pager.per_page) 
          
          args << find_options
          # @options_from_last_find = nil
          pager.replace(send(finder, *args) { |*a| yield(*a) if block_given? })
          
          # magic counting for user convenience:
          pager.total_entries = paginate_count(count_options, args, finder) unless pager.total_entries
        end
        
        
      end

      def paginate_parse_options(options)
        raise ArgumentError, 'parameter hash expected' unless options.respond_to? :symbolize_keys
        options = options.symbolize_keys
        raise ArgumentError, ':page parameter required' unless options.key? :page
    
        if options[:count] and options[:total_entries]
          raise ArgumentError, ':count and :total_entries are mutually exclusive'
        end

        page     = options[:page] || 1
        per_page = options[:per_page] || self.per_page
        total    = options[:total_entries]
        [page, per_page, total]
      end
    
      # Does the not-so-trivial job of finding out the total number of entries
      # in the database. It relies on the ActiveRecord +count+ method.
      def paginate_count(options, args, finder)
        excludees = [:count, :order, :limit, :offset, :readonly]
        excludees << :from unless ActiveRecord::Calculations::CALCULATIONS_OPTIONS.include?(:from)

        # we may be in a model or an association proxy
        klass = (@owner and @reflection) ? @reflection.klass : self

        # Use :select from scope if it isn't already present.
        options[:select] = scope(:find, :select) unless options[:select]

        if options[:select] and options[:select] =~ /^\s*DISTINCT\b/i
          # Remove quoting and check for table_name.*-like statement.
          if options[:select].gsub('`', '') =~ /\w+\.\*/
            options[:select] = "DISTINCT #{klass.table_name}.#{klass.primary_key}"
          end
        else
          excludees << :select # only exclude the select param if it doesn't begin with DISTINCT
        end

        # count expects (almost) the same options as find
        count_options = options.except *excludees

        # merge the hash found in :count
        # this allows you to specify :select, :order, or anything else just for the count query
        count_options.update options[:count] if options[:count]

        # forget about includes if they are irrelevant (Rails 2.1)
        # if count_options[:include] and
        #     klass.private_methods.include_method?(:references_eager_loaded_tables?) and
        #     !klass.send(:references_eager_loaded_tables?, count_options)
        #   count_options.delete :include
        # end

        # we may have to scope ...
        counter = Proc.new { count(count_options) }

        count = if finder.index('find_') == 0 and klass.respond_to?(scoper = finder.sub('find', 'with'))
                  # scope_out adds a 'with_finder' method which acts like with_scope, if it's present
                  # then execute the count with the scoping provided by the with_finder
                  send(scoper, &counter)
                # elsif finder =~ /^find_(all_by|by)_([_a-zA-Z]\w*)$/
                #   # extract conditions from calls like "paginate_by_foo_and_bar"
                #   attribute_names = $2.split('_and_')
                #   conditions = construct_attributes_from_arguments(attribute_names, args)
                #   with_scope(:find => { :conditions => conditions }, &counter)
                else
                  counter.call
                end

        count.respond_to?(:length) ? count.length : count
      end    
    
    
    end # ClassMethods
    
  end
end