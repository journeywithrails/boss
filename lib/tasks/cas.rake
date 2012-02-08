# Tasks for setting up rubycas
RUBYCAS_SERVER_CONFIG_DIR = "/etc/rubycas-server"
 
require 'fileutils'

namespace :sage do
  namespace :cas do
    desc "creates rubycas-server config directory"
    task :config_dir do
      puts RAILS_ENV
      puts "creating #{RUBYCAS_SERVER_CONFIG_DIR}"
      FileUtils.mkdir_p RUBYCAS_SERVER_CONFIG_DIR
    end

    desc "Copies rubycas-server config file from resource"
    task :write_config => ['sage:cas:config_dir'] do
      current_dir = Dir.pwd
      resource_dir = File.join(current_dir, "resource", "rubycas", RAILS_ENV)
      config_file = File.join(resource_dir, "rubycas.yml")
      config_dest = File.join(RUBYCAS_SERVER_CONFIG_DIR, "config.yml")
      FileUtils.cp config_file, config_dest
    end

    desc "Copies root certificate to rubycas-server config. You will need to know the passphrase for the key"
    task :copy_cert => ['sage:cas:config_dir'] do
      current_dir = Dir.pwd
      resource_dir = File.join(current_dir, "resource", "ssl")
      ssl_cert_src = File.join(resource_dir, "castest.billingboss.com.crt")
      ssl_key_src = File.join(resource_dir, "castest.billingboss.com.key")
      ssl_key_dest = File.join(RUBYCAS_SERVER_CONFIG_DIR, "castest.billingboss.com.key")

      FileUtils.cp ssl_cert_src, RUBYCAS_SERVER_CONFIG_DIR
      FileUtils.cp ssl_key_src, RUBYCAS_SERVER_CONFIG_DIR

      puts "removing passphrase from ssl certificate"
      system("openssl rsa -in #{ssl_key_dest} -out #{ssl_key_dest}.open")
      FileUtils.mv "#{ssl_key_dest}.open", ssl_key_dest
    end
    
    desc "creates the cas database. you will need your mysql root password"
    task :create_db => ['sage:cas:write_config'] do
      require 'yaml'
      # read the config file
      conf = YAML.load_file(File.join(RUBYCAS_SERVER_CONFIG_DIR, "config.yml"))
      # get the db conf
      db_conf = conf['database']
      # create the database. drop first in case already exists.
      begin
        puts "dropping old database"
        system("mysqladmin -uroot -p drop #{db_conf['database']}")
      rescue
        # don't care
      end      
      puts "creating database"
      system("mysqladmin -uroot -p create #{db_conf['database']}")
    end
    
    task :setup_server => ['sage:cas:create_db', 'sage:cas:copy_cert'] do
    end
  end
end