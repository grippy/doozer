module Doozer
  class Lib
    
    #Return a ClassName as string from an underscored string. 
    # example: input "example_class" > "ExampleClass"
    def self.classify(klass)
      if klass.index('_')
        klass = klass.split('_')
        parts = []
        klass = klass.each { | part | 
          parts.push(part.capitalize)
        }
        klass = parts.join('')
      else
        klass = klass.capitalize
      end
      return klass
    end

    #Return an underscored string from a ClassName string. 
    # example: input "ExampleClass" > "example_class"    
    def self.underscore(s)
        while true do
          m = /[A-Z]/.match(s)
          break if m.to_s == ''
          s.gsub!(/#{m.to_s}/,"_#{m.to_s.downcase}")
        end
        s.gsub(/^_/,'') # move the first underscore
    end
    
    #Returns a one-level deep folder/file structure and preservers underscores for filename. 
    # example: input "folder_some_file_name" > "folder/some_file_name"
    def self.pathify_first(s)
      if s.index('_')
        parts = s.split('_')
        folder = parts[0]
        file = parts.slice(1, parts.length).join('_')
        s = "#{folder}/#{file}"
      end
      s
    end

  end
end