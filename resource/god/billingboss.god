# run with:  god -c /path/to/proveng.god
# 

# keep backgroundrb running for provisioning engine.

rails_root = ENV['GOD_RAILS_ROOT']||ENV['BB_RAILS_ROOT']
rails_env = ENV['APP_BB_ENVIRONMENT']

God.watch do |w|
  w.name = 'billingboss-backgroundrb'
  w.interval = 30.seconds
  #For troubleshooting:
  #  w.start = "#{rails_root}/script/backgroundrb start -e#{rails_env} 2>&1 >>/home/god.log"
  w.start = "#{rails_root}/script/backgroundrb start -e#{rails_env}"
  w.stop = "#{rails_root}/script/backgroundrb stop -e#{rails_env}"
  w.start_grace = 15.seconds
  w.restart_grace = 15.seconds
  w.pid_file = "#{rails_root}/tmp/pids/backgroundrb_11007.pid"
  w.behavior(:clean_pid_file)

  w.start_if do |start|
    start.condition(:process_running) do |c|
      c.interval = 30.seconds
      c.running = false
    end
  end
end
