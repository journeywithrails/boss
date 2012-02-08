require File.dirname(__FILE__) + '/../test_helper'

#FIXME this should move in princely plugin. Currently we don't run plugin tests -- we should!
# Tests the FileCache storage engine for princely
class FileCacheTest < Test::Unit::TestCase
  
  def setup
  end

  def teardown
  end


  def test_returns_cache_path
    cache = Princely::Storage::FileCache.new(:root_dir => 'some_dir')
    assert_raises Princely::Storage::NoNameError, "calling cache_path with no request_path or cache_name option didn't raise" do
      cache.cache_path
    end
    assert_equal File.join('some_dir', 'bob.pdf'), cache.cache_path(:cache_name => 'bob')
    assert_equal File.join('some_dir', 'mary', 'bob.pdf'), cache.cache_path(:request_path => 'mary/bob.pdf')
    assert_equal File.join('some_dir', 'mary', 'bob.pdf'), cache.cache_path(:request_path => 'mary/bob')
  end
  
  private
end  
