require File.dirname(__FILE__) + '/../test_helper'
require "#{File.dirname(__FILE__)}/../concurrency_helper"


class ConcurrencyTestHelperTest < Test::Unit::TestCase

unless is_windows?

  uses_transaction :test_should_allow_fork, :test_forks_have_own_connections

  def setup
    clear_semaphores
  end
  
  
  def test_should_allow_fork
    assert_nothing_raised do
      active_record_fork do
        assert true
      end
    end      
  end

  def test_should_not_allow_fork
    assert_raise StandardError do
      active_record_fork do
        assert false
      end
    end      
  end
  
  def test_forks_have_own_connections
    pids = []
    2.times do
      active_record_fork do
        bob = ActiveRecord::Base.connection.object_id
      end
    end
  end
  
  def test_creates_semaphore_with_directory
    sem = new_semaphore
    for_christs_sakes = File.join(RAILS_ROOT, 'tmp', 'concurrency_test_helper_test_semaphores')
    assert File.join(RAILS_ROOT, 'tmp', 'concurrency_test_helper_test_sempahores'), sem.directory
  end
  
  def test_semaphore_notifies
    sem = new_semaphore
    sem.ping = [:test_semaphore_notifies]
    sem.notify
    assert File.exists?(File.join(RAILS_ROOT, 'tmp', 'concurrency_test_helper_test_semaphores', 'test_semaphore_notifies'))
  end

  def test_semaphore_waits
    sem1 = new_semaphore
    sem1.wait = [:test_semaphore_waits]
    start = Time.now
    pid = fork do
      status = sem1.wait
      assert status
      exit status ? 77 : 66
    end
    sleep 0.05
    assert_nil Process.waitpid(pid, Process::WNOHANG), "forked semaphore should be waiting"
    write_semaphore(:test_semaphore_waits)
    assert_equal pid, Process.waitpid(pid), "forked semaphore should finish"
    assert ((Time.now - start) < sem1.max_wait), "forked semaphore should catch signal before timeout"
    assert_equal 77, $?.exitstatus, "fork with semaphore should have exit status 77"
  end
  
  
end

end