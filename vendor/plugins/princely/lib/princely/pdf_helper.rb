module Princely # :nodoc:
  module PdfHelper

    def self.included(base)
      base.extend(ClassMethods)
  
      base.class_eval do
        alias_method_chain :render, :princely
        alias_method_chain :render_to_string, :princely
      end
    end

    def render_with_princely(options = nil, &block)
      if options.nil? or !options.is_a?(Hash) or options[:pdf].nil?
        render_without_princely(options, &block)
      else
        options[:name] ||= options.delete(:pdf)
        
        make_and_send_pdf(options.delete(:name), options)
      end
    end  

    def render_to_string_with_princely(options = nil, &block)
      if options.nil? or !options.is_a?(Hash) or options[:pdf].nil?
        render_to_string_without_princely(options, &block)
      else
        options[:name] ||= options.delete(:pdf)
        make_pdf(options, true)
      end
    end  

    
    module ClassMethods
      def pdf_storage; @@pdf_storage; end
      
      def caches_pdfs(options = {})
        options[:storage] ||= 'file'
        options[:root_dir] ||= File.join(RAILS_ROOT, 'public', 'pdf')
        @@pdf_storage = Princely::Storage.const_get("#{options.delete(:storage).to_s.classify}Cache").new(options)
        @@cache_pdfs = true
      end
      
      def cache_pdfs_off!; @@cache_pdfs = false; end
      
      def cache_pdfs?
        @@cache_pdfs ||= false
        @@cache_pdfs
      end
  
    end

  
    private

    def cache_pdfs?
      self.class.cache_pdfs?
    end

    def make_pdf(options = {}, streaming=true)
      if !options.key?(:use_pdf_cache)
        options[:use_pdf_cache] = cache_pdfs?
      end

      options[:stylesheets] ||= []
      options[:template] ||= File.join(controller_path,action_name)
      options[:cache_path] ||= pdf_cache_path(options)
      options[:cache_stale_date] ||= Time.now - 1.day #default expiry is 


      prince = Princely::Prince.new(options.delete(:prince_options))
  
      if options[:use_pdf_cache] and File.exists?(options[:cache_path])
        if File.stat(options[:cache_path]).mtime > options[:cache_stale_date]
          if streaming
            file = File.new(options[:cache_path], "rb") # necessary to do it this way for windows 
            return file.read
          end
        end
      end

      prince.out_path = options[:cache_path] if options[:use_pdf_cache]
  
      # Sets style sheets on PDF renderer
      prince.add_style_sheets(*options[:stylesheets].collect{|style| stylesheet_file_path(style)})
      # Render the estimate to a big html string.
      # Set RAILS_ASSET_ID to blank string or rails appends the current time as a query string
      # to prevent file caching, and prince can't handle that
      begin
        ENV["RAILS_ASSET_ID"] = ''
    
        html_string = options[:text] || render_to_string(:template => options[:template], :layout => options[:layout])
        # Make all paths relative, on disk paths...
        # html_string.gsub!(".com:/",".com/") # strip out bad attachment_fu URLs
        html_string.gsub!(/(href|src)="\//, "\\1=\"#{File.join(RAILS_ROOT, "public")}/") # reroute absolute paths
        html_string.gsub!(/((href|src)="[^?\"]*)(\?[\d]*)"/, "\\1\"") # Remove cache buster
        # Send the generated PDF file from our html string.
        return prince.pdf_from_string(html_string, streaming)
      ensure
        ENV["RAILS_ASSET_ID"] = nil
      end
    end

    def make_and_send_pdf(pdf_name, options = {})
      data = options[:pdf_data]
      data ||= make_pdf(options, true)
      send_data(
        data,
        :filename => pdf_name + ".pdf",
        :type => 'application/pdf'
      ) 
    end

    def stylesheet_file_path(stylesheet)
      stylesheet = stylesheet.to_s.gsub(".css","")
      File.join(ActionView::Helpers::AssetTagHelper::STYLESHEETS_DIR,"#{stylesheet}.css")
    end

    def partition_id(id)
      if raw_value.to_s =~ /\A\d+\Z/
        id_partition = File.join(*("%08d" % @instance.id).scan(/..../))
      else
        id
      end
    end

    def pdf_cache_path(options)
      path = '-'
      if options[:use_pdf_cache]
        options[:request_path] = request.path
        path = self.class.pdf_storage.cache_path(options)
      end
      path
    end
  end
end