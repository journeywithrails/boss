require File.dirname(__FILE__) + '/../test_helper'

# this test assumes that there is a pdf_cache_s3.yml config file in config/
# and that it contains configuration for accessing a public bucket on s3.
# FIXME: should probably be refactored to test functionality and not app setup
# It does not run if ENV['OFFLINE'] is set
class S3CacheTest < Test::Unit::TestCase
  
  def setup
  end

  def teardown
  end

  def test_inits_from_config_file
  end
  
unless ENV['OFFLINE']
end


  private
  def config_path
    'test/fixtures/config/pdf_cache_s3.yml'
  end
end  
