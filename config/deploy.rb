require 'erb'
require 'config/accelerator/accelerator_tasks'


set :keep_releases, 100000 # for some reason the remove old-releases task is borken. Why fix it when we are leaving joyent?
set :stages, %w(staging production)
set :deploy_via, :rsync_with_remote_cache
set :rsync_options, "-az --delete --exclude=.svn --exclude=log --exclude=doc --delete-excluded"

set :application, "billingboss" #matches names used in smf_template.erb
 
# If you aren't deploying to /u/apps/#{application} on the target
# servers (which is the default), you can specify the actual location
# via the :deploy_to variable:
set :application_root, "/var/www/apps/#{application}"
set(:deploy_to) { "#{application_root}/#{stage}" }
 
set :deploy_user, 'billingboss'
set :admin_user, 'admin'
set :user, deploy_user

# If you aren't using Subversion to manage your source code, specify
# your SCM below:
set :scm, :subversion

set :database_yml_in_scm, false
 
# keep a cached code checkout on the server, and do updates each time (more efficient)
# set :deploy_via, :remote_cache
 
# Set the path to svn and rake if needed
set :svn, "/opt/local/bin/svn"
set :rake, "/opt/local/bin/rake"
 
set :domain, '8.12.43.92'
 
role :app, domain
role :web, domain
role :db,  domain, :primary => true
 
set :server_name, "www.billingboss.com"
set :server_alias, "billingboss.com early.billingboss.com"
set :server_port, '80'
set :ssl_server_port, '443'


def cli_prompt(str)
  "\n\n\n<%= BLINK %><%= BOLD %>><%= CLEAR %> <%= BOLD %>#{str}<%= CLEAR %>"
end

def cli_bold(str)
  "<%= BOLD %>#{str}<%= CLEAR %>"
end

def huge_info(str)
  Capistrano::CLI.ui.say(cli_bold("**************************************"))
  Capistrano::CLI.ui.say(cli_bold(str))
  Capistrano::CLI.ui.say(cli_bold("**************************************"))
end

namespace :multistage do
  
  task :ensure do
    unless fetch(:stage, nil)
      Capistrano::CLI.ui.say(cli_prompt("Please choose a stage!"))
      Capistrano::CLI.ui.choose do |menu|
        menu.choices(*stages) do|cmd, details|
          set :stage, cmd.to_s
        end
      end
    end
    huge_info("DEPLOYING TO #{stage.to_s.upcase}")
  end
  
  task :skip do
    set :stage, 'staging'
  end
end

namespace :sage do
  
  task :help do
    puts "Stages"
    puts "-----------------------"
    puts "Possible stages are #{stages.join(', ')}."
    puts "to deploy to a specific stage:"
    puts "  cap production deploy"
    puts
    puts "Branches and tags"
    puts "-----------------------"
    puts "The application can be deployed from a branch or tag,"
    puts "and is NOT deployed from the working copy. However, the"
    puts "configuration files for the deployment DO come from the"
    puts "current working copy: deploy.rb, apache_vhost.erb,"
    puts "smf_template.erb. By default, the app will deploy from"
    puts "tag/current_release."
    puts 
    puts "To deploy from a branch called xxxx:"
    puts "  cap deploy:without_tests -Sbranch=xxxx"
    puts 
    puts "To deploy from a tag called xxxx:"
    puts "  cap deploy:without_tests -Stag=xxxx"
    puts 
    puts "To deploy from trunk"
    puts "  cap deploy:without_tests -Strunk=1"
    puts
    puts "Access"
    puts "-----------------------"
    puts "The setup tasks require an admin user key. Regular"
    puts "deployments require a billingboss key. There is no"
    puts "password access -- deployment can only be done if"
    puts "your public key is on the server."
        
  end
  
  task :pick_repository do
    set :base_repository, "http://sage.svnrepository.com/svn/sage/tornado"
    if variables[:tag]
      set :repository_branch, "tag/#{variables[:tag]}"
    elsif variables[:branch]
      set :repository_branch, "branch/#{variables[:branch]}"
    elsif variables[:trunk]
      set :repository_branch, "trunk"
    else
      unless variables[:repository_set] # can't just look for repository because it will preemptively throw an error if we do
        ok = Capistrano::CLI.ui.agree(cli_prompt("Deploy from tag/current_release? (y/n)"), true)
        unless ok
          sage.help
          exit
        end
        set :repository_branch, "tag/current_release"
      end
    end
    huge_info("DEPLOYING FROM #{repository_branch}")
    set :repository, "#{base_repository}/#{repository_branch}"
    set :repository_set, true
  end
  
  task :as_deploy do
    set :user, variables[:deploy_user]
  end
  
  task :as_admin do
    set :user, variables[:admin_user]
  end
  
  task :setup_app_dir, :roles => [:app, :web] do
    sudo "mkdir -p #{application_root}"
    sudo "chown -R #{application}:#{application} #{application_root}"
    sudo "chmod -R u,g=rwx o=r #{application_root}"
  end

  task :set_app_dir_permissions, :roles => [:app, :web] do
    sage.require_admin_user
    sudo "chown -R #{application}:#{application} #{application_root}/#{stage}"
    sudo "chmod -R ug=rwx,o=r #{application_root}/#{stage}"
  end
  
  task :require_admin_user do
    unless variables[:user] == variables[:admin_user]
      raise Capistrano::Error, "you must use admin user for this task. Re-run with cap sage:as_admin_user <task>"
    end
  end
  task :setup_db_backup, :roles => [:db] do
    run "mkdir -p #{application_root}/#{stage}/backup"
    run "mkdir -p #{shared_path}/cron"
    run "rm -f #{shared_path}/cron/backup_db"
    db_name = "#{application}_#{stage}"
    db_user = "bb_#{stage}" #RADAR, hardcoded name (using application_stage results in too-long name)
    db_password = Capistrano::CLI.ui.ask("what is the #{stage} db password?")
    template = File.read('script/cron/backup_db.erb')
    buffer = ERB.new(template).result(binding)
    put buffer, "#{shared_path}/cron/backup_db", :mode => 700
  end
  
end

on :start, "multistage:skip", :only => "sage:help" # ok I give up trying to skip the pick stage on task sage:help. catch-22 city
require 'capistrano/ext/multistage' # capistrano multistage setup must be after the on :start "sage:pick_stage"

on :start, "sage:pick_repository", :except => (stages + ["sage:help"])


# Example dependancies
# depend :remote, :command, :gem
# depend :remote, :gem, :money, '>=1.7.1'
# depend :remote, :gem, :mongrel, '>=1.0.1'
# depend :remote, :gem, :image_science, '>=1.1.3'
# depend :remote, :gem, :rake, '>=0.7'
# depend :remote, :gem, :BlueCloth, '>=1.0.0'
# depend :remote, :gem, :RubyInline, '>=3.6.3'
#  
deploy.task :restart do
  accelerator.smf_restart
  accelerator.restart_apache
end
 
deploy.task :start do
  accelerator.smf_start
  accelerator.restart_apache
end
 
deploy.task :stop do
  accelerator.smf_stop
  accelerator.restart_apache
end
 
after :deploy, 'deploy:cleanup'

namespace :deploy do
  
  task :setup_ssl, :roles => [:app, :web] do
    sage.require_admin_user
    run "mkdir -p #{shared_path}/ssl.crt"
    crt = File.read("resource/ssl/#{application}.crt")
    
    sudo "chmod -R 777 #{shared_path}/ssl.crt"
    sudo "rm -f #{shared_path}/ssl.crt/#{application}.crt"
    put crt, "#{shared_path}/ssl.crt/#{application}.crt", :mode => 600

    run "mkdir -p #{shared_path}/ssl.key"
    key = File.read("resource/ssl/#{application}.key")
    sudo "rm -f #{shared_path}/ssl.key/#{application}.key.ori"
    sudo "chmod -R 777 #{shared_path}/ssl.key"
    put key, "#{shared_path}/ssl.key/#{application}.key.ori"

    sudo "chmod -R 600 #{shared_path}/ssl.key"
    sudo "chown -R webservd:root #{shared_path}/ssl.key"
  end

  desc "instructions for manual steps required to complete deploy:setup"
  task :manual_instructions do
    puts
    puts
    puts "************************************************"
    puts "To complete the setup:"
    puts
    puts "1. remove the passphrase from the ssl key in"
    puts "   #{shared_path}/ssl.key by running"
    puts "sudo openssl rsa -in #{shared_path}/ssl.key/#{application}.key.ori \\"
    puts "-out #{shared_path}/ssl.key/#{application}.key"
  end
  
  # each file_column must be added here
  task :setup_file_column_dirs, :roles => [:app, :web] do
    run "mkdir -p #{shared_path}/logo"
  end
  
  task :setup_pdf_dirs, :roles => [:app, :web] do
    run "mkdir -p #{shared_path}/pdf"
  end
  
  # task :setup_theme_dirs, :roles => [:app, :web] do
  #   run "mkdir -p #{shared_path}/themes"
  # end
  # 
  task :import_schema do
    rake = fetch(:rake, "rake")
    rails_env = fetch(:rails_env, stage)

    run "cd #{current_release}; #{rake} RAILS_ENV=#{rails_env} db:schema:load"
  end
  
  task :cold do
    logger.trace '---->  MY cold deploy'
    set(:run_tests, "0")
    logger.trace '----> do update'
    update
    # migrate
    # logger.trace '----> do import schema'
    import_schema
    start
  end

  task :link_shared_dirs do
    link_file_column_dirs
    link_pdf_dirs
    # link_theme_dirs
  end
  
  task :link_file_column_dirs, :roles => [:app, :web] do
    run "ln -nfs #{shared_path}/logo #{current_path}/public/logo"
  end
  
  task :link_pdf_dirs, :roles => [:app, :web] do
    run "ln -nfs #{shared_path}/pdf #{current_path}/public/pdf"
  end
  
  # NOT a good idea ?!?!?!
  # task :link_theme_dirs, :roles => [:app, :web] do
  #   run "ln -nfs #{shared_path}/themes #{current_path}/public/themes"
  # end

  desc "generate database yml file from template in config/database.{stage}.yml "
  task :generate_database_yml, :roles => :app do   
    run "mkdir -p #{deploy_to}/#{shared_dir}/config/" 
    template = File.read("config/database.#{stage}.yml")
    stage_password = Capistrano::CLI.ui.ask("what is the #{stage} db password?")
    test_password = Capistrano::CLI.ui.ask("what is the test db password?")
    buffer = ERB.new(template).result(binding)
    put buffer, "#{deploy_to}/#{shared_dir}/config/database.yml"
  end

  desc "Link in the database.yml" 
  task :symlink_database_yml, :roles => :app do
    unless database_yml_in_scm
      run "rm -f #{release_path}/config/database.yml"
      run "ln -nfs #{deploy_to}/#{shared_dir}/config/database.yml #{release_path}/config/database.yml" 
    end
  end


  desc "Minify JS and CSS files"
  task :minify_resource_files do
    rake = fetch(:rake, "rake")
    rails_env = fetch(:rails_env, stage)
    run "cd #{current_release}; #{rake} RAILS_ENV=#{rails_env} minify_resource_files resource=js"
    run "cd #{current_release}; #{rake} RAILS_ENV=#{rails_env} minify_resource_files resource=css"
  end
  
end

before "deploy:symlink", "deploy:setup_file_column_dirs", "deploy:setup_pdf_dirs"

after "deploy:symlink", "deploy:link_shared_dirs"

after "deploy:finalize_update", "deploy:symlink_database_yml"

#always disable/enable web during deployment
before "deploy", "deploy:web:disable"
after "deploy", "deploy:web:enable", "deploy:minify_resource_files", "send_tweet"
after "deploy:rollback", "send_tweet"
before "deploy:setup", "sage:as_admin"
after "deploy:setup", "deploy:generate_database_yml", "deploy:setup_ssl", "sage:set_app_dir_permissions", "deploy:manual_instructions"


desc 'posts to twitter that an application has been deployed to a web server'
task :send_tweet do
  require 'open-uri'
  require 'net/http'

  if ENV['OS'] == 'Windows_NT'
    who = `echo %USERDOMAIN%:%USERNAME%`
  else
    who = `whoami`
  end
  if fetch(:run_tests, "1") == "0"
    with_tests = "without tests"
  else
    with_tests = "with tests"
  end
  url = URI.parse('http://twitter.com/statuses/update.xml')
  req = Net::HTTP::Post.new(url.path)
  req.basic_auth 'bbdeploy' + ":" + 'simply#1', ''
  req.set_form_data({'status' => "#{Time.new}: #{who} deployed #{application} from #{repository_branch} to #{stage} #{with_tests}"})
  res = Net::HTTP.new(url.host, url.port).start {|http| http.request(req) }
end

