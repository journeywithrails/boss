Capistrano::Configuration.instance(:must_exist).load do
  namespace :accelerator do
    
    desc "Adds a SMF for the application"
    task :create_smf, :roles => :app do
      # run "mkdir -p /home/#{user}/bin"
      # # # write the svcadm scripts. We use scripts so we can avoid giving billingboss sudo to svcadm in general
      # put "#!/bin/bash\nsvccfg import #{shared_path}/#{application}-smf.xml\n", "/home/#{user}/bin/import_#{application}_service"
      # run "chmod u=rwx,go= /home/#{user}/bin/import_#{application}_service"
      # put "#!/bin/bash\nsvccfg delete /network/mongrel/billingboss", "/home/#{user}/bin/delete_#{application}_service"
      # run "chmod u=rx,go= /home/#{user}/bin/delete_#{application}_service"
      # put "#!/bin/bash\nsvcadm refresh svc:/network/http:cswapache2", "/home/#{user}/bin/restart_apache_#{application}"
      # run "chmod u=rx,go= /home/#{user}/bin/restart_apache_#{application}"
      # put "#!/bin/bash\nsvcadm enable -r /network/mongrel/billingboss:$1", "/home/#{user}/bin/start_#{application}_service"
      # run "chmod u=rx,go= /home/#{user}/bin/start_#{application}_service"
      # put "#!/bin/bash\nsvcadm disable /network/mongrel/billingboss:$1", "/home/#{user}/bin/stop_#{application}_service"
      # run "chmod u=rx,go= /home/#{user}/bin/stop_#{application}_service"
      # 
      # because one smf file for all stages
      if stage.to_s == 'production'
        sage.require_admin_user
        puts "set variables"
        service_name = application
        working_directory = application_root
      
        template = File.read("config/accelerator/smf_template.erb")
        buffer = ERB.new(template).result(binding)

        put buffer, "#{shared_path}/#{application}-smf.xml"
      
        # using RABC
        sudo "svccfg import #{shared_path}/#{application}-smf.xml"
        # smffile = "#{shared_path}/#{application}-smf.xml"
        # sudo "/home/#{user}/bin/import_#{application}_service #{smffile}"
       end
    end
  
    desc "sets up rbac permissions on svc for app & apache for deploy & admin user"

    task :setup_rbac do
      sage.require_admin_user
      sudo "usermod -A \"solaris.smf.manage.mongrel/#{application},solaris.smf.manage.http\" #{admin_user}"
      sudo "usermod -A \"solaris.smf.manage.mongrel/#{application},solaris.smf.manage.http\" #{deploy_user}"
    end
    
    desc "Creates an Apache 2.2 compatible virtual host configuration file"
    task :create_vhost, :roles => :web do
      public_ip = ""
      run "ifconfig -a | ggrep -A1 e1000g0 | grep inet | awk '{print $2}'" do |ch, st, data|
        public_ip = data.gsub(/[\r\n]/, "")
      end
 
      cluster_info = YAML.load(File.read("config/mongrel_cluster-#{stage}.yml"))
 
      start_port = cluster_info['port'].to_i
      end_port = start_port + cluster_info['servers'].to_i - 1
      public_path = "#{current_path}/public"
      
      template = File.read("config/accelerator/apache_vhost-#{stage}.erb")
      buffer = ERB.new(template).result(binding)
      
      put buffer, "#{shared_path}/#{application}-apache-vhost.conf"
      sudo "cp #{shared_path}/#{application}-apache-vhost.conf /opt/csw/apache2/etc/virtualhosts/#{application}-#{stage}.conf"
      
      # virtual_min_vhost = "/opt/csw/apache2/etc/virtualhosts/#{server_name}.conf"
      # sudo "test -f #{virtual_min_vhost} && rm #{virtual_min_vhost}.bak"
      # 
      # bare_name = server_name.split('.').reverse[0..1].reverse.join('.')
      # virtual_min_vhost = "/opt/csw/apache2/etc/virtualhosts/#{bare_name}.conf"
      # sudo "test -f #{virtual_min_vhost} && cp #{virtual_min_vhost}.bak"
      # 
      
      # very bad to restart apache at this point as the vhost refers to things which are not there until doing a deploy:cold!
      # restart_apache
    end
    
    desc "Restart apache"
    task :restart_apache, :roles => :web do
      # if RABC
      run "svcadm refresh svc:/network/http:cswapache2"
      # sudo "/home/#{user}/bin/restart_apache_#{application}"
      svcs_app
    end
    
    desc "Stops the application"
    task :smf_stop, :roles => :app do
      # if RABC
      run "svcadm disable /network/mongrel/#{application}:#{stage}"
      # sudo "/home/#{user}/bin/stop_#{application}_service #{stage}"
    end
  
    desc "Starts the application"
    task :smf_start, :roles => :app do
      # if RABC
      run "svcadm enable /network/mongrel/#{application}:#{stage}"
      # sudo "/home/#{user}/bin/start_#{application}_service #{stage}"
    end
  
    desc "Restarts the application"
    task :smf_restart do
      smf_stop
      smf_start
      svcs_app
    end
 
    desc "Deletes the configuration"
    task :smf_delete, :roles => :app do
      # because one smf file for all stages
      if stage.to_s == 'production'
        # if RABC
        run "svccfg delete /network/mongrel/#{application}"
        # sudo "/home/#{user}/bin/delete_#{application}_service"
      end
    end
 
    desc "Shows all Services"
    task :svcs, :roles => :app do
      run "svcs -a" do |ch, st, data|
        puts data
      end
    end
    
    desc "shows relevant Services"
    task :svcs_app, :roles => :app do
      run "svcs | grep -e\"mongrel\" -e\"http\"" do |ch, st, data|
        puts data
      end
      
    end
    
    desc "After setup, creates Solaris SMF config file and adds Apache vhost"
    task :setup_smf_and_vhost do
      create_smf
      create_vhost
    end
    
  end
  
  after 'deploy:setup', 'accelerator:setup_smf_and_vhost'
  
end
