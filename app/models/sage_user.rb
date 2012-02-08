# RADAR: remove this class after BB with sso goes live and users have been consolidated
class SageUser < ActiveRecord::Base
  if %w{production staging}.include?(RAILS_ENV)  
    config_path = "/home/rails/sageaccountmanager/current/config/database.yml"
  else 
    config_path = "/home/mahesh/tornado_dev/home/mahesh/src/sageaccountmanager/config/database.yml"
  end  
  puts "config_path: #{config_path.inspect}"
  conf = YAML.load_file(config_path)
  conf = conf.with_indifferent_access
  puts "conf: #{conf.inspect}"
  puts "RAILS_ENV: #{RAILS_ENV.inspect} ENV['RAILS_ENV']: #{ENV['RAILS_ENV'].inspect}"
  my_conf = conf[RAILS_ENV]
  puts "my_conf: #{my_conf.inspect}"
  establish_connection my_conf
end
