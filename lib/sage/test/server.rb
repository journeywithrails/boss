require 'yaml'

# This class feeds cruise control with yak hair

module Sage
  module Test
    class Server
      class << self
        def servers
          @servers ||= {}
        end
        
        def load_many(conf)
          conf[:servers].each do |name, opts|            
            load(conf, opts, name)
          end 
        end
        
        def load(base_conf, conf, name=nil)
          name ||= conf[:name]
          raise "can't load server with no name.\nconfig:\n#{conf.inspect}" if name.blank?
          name = name.to_sym
          conf[:environment] ||= base_conf[:environment]
          src_dir = "/"
          src_dir = base_conf[:src_dir] unless base_conf[:src_dir].blank?
          src_dir = File.join(src_dir, conf[:src_dir]) unless conf[:src_dir].blank?
          Sage::Test::Server.servers[name] = Sage::Test::Server.new(name, src_dir, conf)
        end

        def configure(config_file=nil)
          if config_file.nil?
            config_name = ENV['SSO_INTEGRATION_CONFIG'] || "test_local"             
            config_name += ".yml"
            
            if Object.const_defined?(:RAILS_ROOT)
              config_dir = File.join(RAILS_ROOT, 'test', 'fixtures', 'config', 'sso_integration')
            elsif Object.const_defined?(:Merb)
              config_dir = File.join(Merb.root, 'spec', 'fixtures')
            end
            config_file = File.join(config_dir, config_name)
            puts "Sage::Test::Server config: #{config_file}"
          end
          
          if File.exists?(config_file)
            config = YAML::load(IO.read(config_file)).with_indifferent_access
            load_many(config)
          else
            puts "no config file found at #{config_file}"
            raise Exception.new("no config file found at #{config_file}")
          end
        end
        

        def ensure(name)
          name = name.to_sym
          raise "Don't know about server #{name.to_s}" if servers[name].nil?
          servers[name].ensure
        end
        
        def method_missing( method_sym, *args )
          if (match = method_sym.to_s.match /has_(\w+)\?/)
            return servers[match[1].to_sym]
          end
          return servers[method_sym] unless servers[method_sym].nil?
          super
        end
        
        def kill_all
          servers.values.each{|server| server.kill}
          return ""
        end
        
        def ensure_all
          servers.values.each{|server| server.ensure}
          return ""
        end
      end
      
      attr_accessor :host, :port, :protocol, :base_path, :name, :src_dir, :framework, :local, :ssh_key, :servername

      def initialize(name, src_dir, options={})
        @name = name
        @port =  options[:port] || ''
        @ssl_port =  options[:ssl_port] || ''
        @host = options[:host] || 'localhost'
        @protocol = options[:protocol] || 'http'
        @base_path = options[:base_path] || ''
        @framework = options[:framework] || 'rails'
        @sudo = options[:use_sudo] ? 'sudo ' : ''
        @environment = options[:environment] || 'test'
        @local =  options[:local].blank? ? false : ((options[:local].to_s.downcase =~ /(true|^1)/) && true)
        @src_dir = src_dir
        @ssh_key =  options[:ssh_key] if options[:ssh_key]
        @servername =  options[:servername] if options[:servername]
      end
      
      def url(for_host=nil)
        for_host ||= @host
        "#{@protocol}://#{for_host}" + (@port.blank? ? "" : ":#{@port}") + @base_path
      end
      
      def secure_url(for_host=nil)
        raise "can't create secure_url for server #{@name} because it does not have ssl_port defined" if (@protocol != 'https' && @ssl_port.blank?)
        for_host ||= @host
        port = @port if @protocol == 'https'
        port ||= @ssl_port
        port = ((port.to_s == '443') ? "" : ":#{port.to_s}")
        "https://#{for_host}" + port + @base_path
      end
      
      def host_with_port
        "#{@host}" + (@port.blank? ? "" : ":#{@port}")
      end

      def local?
        @local
      end

        # Return true if server could be "pinged" at tcp port
        # otherwise false.
      def ping(timeout=5)
        begin
          timeout(@timeout) do
            tcp_port = self.port
            if self.port.blank?
              tcp_port = case self.protocol
              when 'http'
                '80'
              when 'https'
                '443'
              end
            end  
            puts "pinging #{self.host} #{tcp_port}" if $log_on
            s = TCPSocket.new(self.host, tcp_port)
            s.close
            true
          end
        rescue Errno::ECONNREFUSED
          false
        rescue Timeout::Error, StandardError
          false
        end
      end
      
      def ensure
        if self.local?
          self.launch
        else
          raise "#{self.to_s} is not running" unless self.ping
        end
      end

      def chatty_cmd(cmd)
        cmd += " 2>&1"
        if $log_on
          puts "#{cmd}: " +`#{cmd}` 
        else
          `#{cmd}`
        end
      end
      
      def kill
        case @framework
        when 'merb'
          # chatty_cmd("merb -k #{@port}") # for some reason this does not work in script tho it does in cmd line
          pid_file = File.join(@src_dir,"log/merb.pids/mongrel.pid")
          # kill_from_pidfile pid_file 
          kill_process_matching "merb .* -p #{@port}"
          `rm #{pid_file}`
        when 'rails' 
          pid_file = File.join(@src_dir,'tmp/pids/mongrel.pid')
          # kill_from_pidfile pid_file
          kill_process_matching "mongrel_rails .* -p #{@port}"
          `rm #{pid_file}`
        when 'tomcat'
          chatty_cmd "#{@sudo}$CATALINA_HOME/bin/shutdown.sh"
        when 'mamp'
          chatty_cmd "/Applications/MAMP/Library/bin/apachectl stop"
        end
      end
      
      def kill_from_pidfile(pidfile)
        pid = File.read(pidfile)
        `kill -9 #{pid}`        
      end
      
      def kill_process_matching(str)
        process = `ps -x | grep '#{str}' | grep -v ' grep '`
        if  process.blank?
          puts "could not find a process like #{str}" if $log_on
          return
        end
        pid = process[/^\d+/]
        `kill -9 #{pid}`
      end
      
      def http
        Net::HTTP.new( @host, @port )
      end
      
      def rest_delete( path, data =nil, api_key = nil )
        path = @base_path + '/' + path
        path << to_query_string( data ) if data
        headers = prepare_headers
        rsp = http.delete( path , headers )
        # puts "delete #{path} returned 404" if rsp.code.to_i != 200
        return nil
      end

      def prepare_headers(format='xml')
        headers = { "Content-Type" => "text/xml; charset=utf-8" }
        headers["format"]=format
        return headers
      end

      def to_query_string( data )
        qs = "?"
        params.each{ |k,v| qs << "#{k}=#{v}&" }
        qs.chop!
      end

      def to_s
        "#{self.name} (#{self.url})"
      end
      
      def launch(force=false)
        down = !self.ping
        should_launch = force || down
        
        if should_launch
          puts "launching #{@name} (#{@framework})"
          case @framework
          when 'merb'
            chatty_cmd  "cd #{@src_dir}; bin/merb -d -p #{@port} -e#{@environment}"
          when 'rails'
            pid_file = File.join(@src_dir,'tmp/pids/mongrel.pid')
            `rm #{pid_file}`
            chatty_cmd  "cd #{@src_dir}; ruby script/server -d -p #{@port} -e#{@environment}"
          when 'tomcat'
            chatty_cmd "#{@sudo}$CATALINA_HOME/bin/startup.sh"
          when 'mamp'
            chatty_cmd "open /Applications/MAMP/MAMP.app"
          end
        end
        tries = 1
        while(!self.ping && tries < 8)
          sleep (tries * 0.5)
          tries +=1
        end
        raise "#{self.name} did not come up" if tries > 7
      end

      def rake(tasks)
        case @framework
        when 'merb'
          env = 'MERB_ENV='
          cmd = "bin/rake"
        when 'rails'
          env = 'RAILS_ENV='
          cmd = 'rake'
        else
          env = 'ENVIRONMENT='
          cmd = 'rake'
        end
        env += @environment
        
        rake_cmd = "cd #{@src_dir}; #{env} #{cmd} #{tasks}"
        
        run_on_server rake_cmd
      end
      
      def run_on_server(cmd)
        if local?
          chatty_cmd cmd
        else
          raise "no servername for remote #{@name}" if @servername.blank?
          ssh_cmd = 'ssh'
          ssh_cmd += " -i #{@ssh_key} " if @ssh_key
          ssh_cmd += "root@#{@servername}"
          chatty_cmd "#{ssh_cmd} '#{cmd}'"
        end
      end
      
    end
  end
end