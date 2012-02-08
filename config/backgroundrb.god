RAILS_ROOT = File.dirname(File.dirname(__FILE__))

God.watch do |w|
  script = "#{RAILS_ROOT}/script/backgroundrb"
  w.name = "backgroundrb"
  w.group = "backgroundrb-daemon"
  w.interval = 60.seconds
  w.start = "#{script} start"
  w.stop = "#{script} stop"
  w.start_grace = 20.seconds
  w.restart_grace = 20.seconds
  w.pid_file = "#{RAILS_ROOT}/tmp/pids/backgroundrb_11006.pid"
  
  w.behavior(:clean_pid_file)
  
  w.start_if do |start|
    start.condition(:process_running) do |c|
      c.interval = 10.seconds
      c.running = false
    end
  end
  
  w.restart_if do |restart|
    restart.condition(:memory_usage) do |c|
      c.above = 100.megabytes
      c.times = [3, 5]
    end
    
    restart.condition(:cpu_usage) do |c|
      c.above = 80.percent
      c.times = 5
    end
  end
  
  w.lifecycle do |on|
    on.condition(:flapping) do |c|
      c.to_state = [:start, :restart]
      c.times = 5
      c.within = 5.minute
      c.transition = :unmonitored
      c.retry_in = 10.minutes
      c.retry_times = 5
      c.retry_within = 2.hours
    end
  end
end