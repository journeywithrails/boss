# Prince XML Ruby interface. 
# http://www.princexml.com
#
# Library by Subimage Interactive - http://www.subimage.com
#
#
# USAGE
# -----------------------------------------------------------------------------
#   prince = Prince.new()
#   html_string = render_to_string(:template => 'some_document')
#   send_data(
#     prince.pdf_from_string(html_string),
#     :filename => 'some_document.pdf'
#     :type => 'application/pdf'
#   )
#
require 'logger'
require 'session'

module Princely # :nodoc:
  class Prince
    attr_accessor :exe_path, :style_sheets, :log_file, :logger, :out_path, :network
    cattr_accessor :windows_executable

    # Initialize method
    #
    def initialize(options={})
      options ||= {}
      # Finds where the application lives, so we can call it.
      @network = options[:network];
      @exe_path = options[:executable]
      if is_windows?
        RAILS_DEFAULT_LOGGER.error("OH NO! WINDOWS")
        @exe_path ||= quote_for_windows(Prince.windows_executable)
        RAILS_DEFAULT_LOGGER.error(@exe_path)
        raise StandardError, "there is no prince xml executable!" unless File.exists?(Prince.windows_executable)
      else
        @exe_path ||= `which prince`.chomp
        @exe_path = '/usr/local/bin/prince' if @exe_path.blank? #RADAR under some circumstances which was failing and time to discover why was not allocated
        raise StandardError, "there is no prince xml executable!" unless File.exists?(@exe_path)
      end
    	@style_sheets = ''
    	@log_file = "#{RAILS_ROOT}/log/prince.log"
    	@logger = RAILS_DEFAULT_LOGGER
    	@out_path = '-'
    end
  
    # Sets stylesheets...
    # Can pass in multiple paths for css files.
    #
    def add_style_sheets(*sheets)
      for sheet in sheets do
        @style_sheets << " -s #{sheet} "
      end
    end
  
    # Returns fully formed executable path with any command line switches
    # we've set based on our variables.
    #
    def exe_path
      # Add any standard cmd line arguments we need to pass
        @exe_path + " --input=html --server --log=#{@log_file} " + (@network ? '' : "--no-network" ) + @style_sheets
    end
  
    # Makes a pdf from a passed in string.
    #
    # Returns PDF as a stream, so we can use send_data to shoot
    # it down the pipe using Rails.
    #
    def pdf_from_string(string, streaming=true)
      tempfile = nil
    
      if @out_path == '-' and !streaming
        raise StandardError, 'streaming was false but no output file path was supplied'
      end
    
      if @out_path == '-' and is_windows?
        # Windows will use a tempfile insead of streaming
        tempfile = Sage::NamedTempFile.new('pdf')
        @out_path = tempfile.hold
      end
    
      path = self.exe_path()
      # Don't spew errors to the standard out...and set up to take IO 
      # as input and output
      if @out_path == '-'
        path << " --silent - -o #{out_path}"
      else
        path << " --silent - -o #{quote_for_windows(out_path)}"
      end
    
      # Show the command used...
      # logger.info "\n\nPRINCE XML PDF COMMAND"
      # logger.info path
      # logger.info ''
    
    
      FileUtils.mkdir_p File.dirname(@out_path) unless @out_path == '-'

      # Actually call the prince command, and pass the entire data stream back.
      if is_windows?
        pdf = IO.popen(path, "w+")
        pdf.puts(string)
        pdf.close_write
        result = pdf.gets(nil)
      else
        pdf = Session::Bash.new
        result, err = pdf.execute(path, :stdin => string)
        pdf.close!
      end

      if streaming
        if @out_path == '-'
          return result
        else
          if tempfile.nil?
            file = File.new(@out_path, "rb") # necessary to do it this way for windows 
            return file.read
          else
            tempfile.open
            return tempfile.binmode.read
          end
        end
      else
        return $?
      end
    end

    def is_windows?
      return ENV['OS'] == 'Windows_NT'
    end
  
    def quote_for_windows(filepath)
      if is_windows?
        '"' + filepath + '"'
      else
        filepath
      end
    end
  
  end
end