module Test
  module Concurrency
    class Semaphore
      attr_accessor :ping, :wait, :pong, :directory, :max_wait, :log
      
      def self.register_semaphore_ownership(klass)
        self.semaphore_owners << klass
      end
      
      def self.semaphore_owners
        @@semaphore_owners ||= []
      end
      
      def self.clear_semaphores
        self.semaphore_owners.each{|owner| owner.clear_checkpoints }
      end
      
      def initialize(directory, options = {})
        @directory = directory
        @ping = [options[:ping]].flatten
        @wait = [options[:wait]].flatten
        @pong = [options[:pong]].flatten
        @max_wait = options[:max_wait] || 3
        @did_wait = false
        @log = options[:log] || 0
      end

      def notify(*sems)
        label = ''
        if sems.empty?
          sems = @did_wait ? @pong : @ping
          label = @did_wait ? '(pong)' : '(ping)'
        end
        sems = [sems].flatten
        sems.each do |sem|
          unless sem.nil?
            BillingTest.log "-- notify#{label} #{sem}: #{File.exists?(semaphore_path(sem)) ? 'ALREADY EXISTED!' : ''}"  if $log_concurrency #tmp_on
            FileUtils.touch(semaphore_path(sem))
          end
        end
      end

      def wait(*sems)
        sems = @wait if sems.empty?
        sems = [sems].flatten
        @did_wait = true
        BillingTest.log "-- wait for #{sems.inspect} for #{@max_wait}" if $log_concurrency #tmp_on
        return true if sems.empty?
        ok = false
        start = Time.now
        while ((no_file = ! sems.all?{ |sem| File.exists?(semaphore_path(sem))} ) and (Time.now < (start + @max_wait)))
          BillingTest.log "-- waiting for #{sems.inspect}"  if $log_concurrency #tmp_on
          sleep 0.1
        end
        BillingTest.log "-- wait -- returning #{!no_file}"  if $log_concurrency #tmp_on
        return ( not no_file )
      end

      def notify_and_wait
        notify
        wait
        notify
      end

      def semaphore_path(sem)
        #puts "in semaphore_path, sem is: #{sem} and directory is: #{@directory}"
        File.join @directory, sem.to_s
      end
      
    end
    
  end
end

class Test::Unit::TestCase
  def new_semaphore(options={})
    Test::Concurrency::Semaphore.new(self.semaphore_directory, options)
  end

  def semaphore_directory
    dir = File.join(RAILS_ROOT, 'tmp', "#{self.class.name.underscore}_semaphores")
    FileUtils.mkdir_p dir
    dir
  end

  def clear_semaphores
    Test::Concurrency::Semaphore.clear_semaphores
    FileUtils.rm_r semaphore_directory
  end
    
  def write_semaphore(sem)
    semaphore = new_semaphore
    semaphore.ping =  sem
    semaphore.notify
  end
  
  def waiting_for(arg)
    options = case arg
    when Hash
      arg
    when Symbol, String
      {:wait => arg.to_sym}
    end
    sem = new_semaphore(options)
    sem.wait
    yield
    sem.notify
  end
  
  # creates a fork with it's own private connection to the database  
  def fork_with_new_connection(config, klass = ActiveRecord::Base)
    raise StandardError, "can't use forks with transactional fixtures" if self.use_transactional_fixtures?
    fork do
      begin
        klass.establish_connection(config)
        yield
      ensure
        klass.remove_connection
      end
    end
  end
  
  def active_record_fork(&block)
    begin
      config = ActiveRecord::Base.remove_connection
      fork_with_new_connection(config, &block)
    ensure
      ActiveRecord::Base.establish_connection(config)
    end
  end
  
  
end