module Princely
  module Storage
    class FileCache

      attr_accessor :root_dir
      
      def initialize(options={})
        @root_dir = options[:root_dir] 
      end
      
      def cache_path(options={})
        if options[:request_path].blank? and options[:cache_name].blank?
          raise NoNameError, "cannot construct cache_path without either a request_path or a cache_name"
        end
        
        path = root_dir
        path = File.join(path, options[:request_path].split('/')) if options[:request_path]
        if options[:cache_name]
          path = File.dirname(path) if path =~ /\.pdf$/
          path = File.join(path, options[:cache_name])
        end
        path += ".pdf" unless path =~ /\.pdf$/
        path
      end
    end
  end
end