require 'singleton'
class FirefoxApp
  include Singleton
  
  attr_writer :profile
  
  def bin_path
    "/Applications/Firefox.app/Contents/MacOS/firefox-bin"
  end
  

  def launch_path
    puts "FirefoxApp.launch_path"
    "#{bin_path} -jssh -no-remote -P #{profile}"
    # "#{bin_path} -jssh -jssh-port 9997 -no-remote -P #{profile}"
  end
  
  def launch(kill_on_exit=true)
    @pid = find_process
    if @pid.nil?
      puts "launch with #{launch_path}"
      Thread.new { `#{launch_path}`}
      @pid = find_process
    end
    if kill_on_exit
      at_exit {FirefoxApp.instance.kill}
    end
    @pid
  end
  
  def kill
    @pid = find_process
    Process.kill('SIGTERM', @pid) unless @pid.nil?
  end
  
  def profile
    @profile ||= "sage_test"
  end
  
  def find_process
    processes = `ps`.split("\n")
    firefox_process = processes.find{|p| p.include?('firefox') && p.include?('-jssh') && p.include?("-P #{self.profile}") }
    return nil if firefox_process.nil?
    pid = firefox_process.slice(/^ *\d+ /).chop.to_i
    pid
  end
    
end