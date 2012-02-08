require File.dirname(__FILE__) + '/../test_helper'

class TestController < ActionController::Base
  HTML = <<-EOQ
  <html>
  <head><title>I am a PDF</title></head>
  <body>
    I have been generated at ###
  </body>
  </html>
  EOQ
  
  
  def give_me
    # puts "REQUEST PATH: #{request.path}"
    # puts "request.env[\"HTTP_ACCEPT\"]: #{request.env["HTTP_ACCEPT"].inspect}"
    # puts "params[:format]: #{params[:format].inspect}"
    # puts "cache_pdfs?: #{TestController.cache_pdfs?.inspect}"
    # puts "params: #{params.inspect}"
    respond_to do |format|
       format.pdf { render :pdf => params[:name], 
         :text => HTML.sub('###', Time.now.to_s),
         :cache_name => params[:cache_name] }
    end
  end

  def give_me_expired
    respond_to do |format|
       format.pdf { render :pdf => params[:name], 
         :text => HTML.sub('###', Time.now.to_s),
         :cache_name => params[:cache_name],
         :cache_stale_date => Time.now }
    end
  end
end


class PdfGeneratorTest < ActionController::TestCase


  fixtures :invoices
  
  tests TestController
  def setup
    ActionController::Routing::Routes.draw do |map| 
      map.connect '/:controller/:action/:id'
      map.connect '/:controller/:action/:id.:format'
    end
    FileUtils.rm_r cache_dir, :force => true
    assert !File.exists?(cache_dir), "cache_dir #{cache_dir} should have been deleted"
    FileUtils.mkdir_p cache_dir
    assert File.exists?(cache_dir), "cache_dir #{cache_dir} should have been deleted"
    # todo : test localization and pdf export
    @controller.stubs(:init_language).returns(true)
  end
  
  def teardown
    if Test::Unit::TestCase.is_windows?
      #windows needs files to be closed before the next action is performed.
      GC.start # finalize and close file objects in Windows so they can be unlinked.
    end
    FileUtils.rm_r cache_dir, :force => true
    $log_on = false
    load 'config/routes.rb'
  end
  
  def test_should_generate_pdf
    TestController.cache_pdfs_off!
    get :give_me, :name => 'test', :format => 'pdf'
    assert_response :success
    assert_match /%PDF/, @response.body
    assert_match /%EOF/, @response.body
    assert_equal 'application/pdf', @response.headers["type"]
    assert_match /attachment/, @response.headers['Content-Disposition']
    assert_match /test\.pdf/, @response.headers['Content-Disposition']
  end
  
  
  def test_should_cache_pdf_as_file
    setup_cache_test
    assert (not File.exists?(@expected_path)), "to start should be no file at #{@expected_path}"
    get :give_me, :format => 'pdf', :name => 'cache_test', :cache_name => 'cache_test'
    assert File.exists?(@expected_path), "should now be a file at #{@expected_path}"
  end
  
  
  def test_should_use_cached_pdf_if_found
    setup_cache_test
    get :give_me, :format => 'pdf', :name => 'cache_test', :cache_name => 'cache_test'
    first_file_time = File.stat(@expected_path).ctime
    get :give_me, :format => 'pdf', :name => 'cache_test', :cache_name => 'cache_test'
    assert_equal File.stat(@expected_path).ctime, first_file_time
  end
  
  def test_should_expire_cache
    setup_cache_test
    assert (not File.exists?(@expected_path))
    get :give_me, :format => 'pdf', :name => 'cache_test', :cache_name => 'cache_test'
    first_file_time = File.stat(@expected_path).mtime
    # 1 second resolution for ntfs file system.
    sleep 1
    get :give_me, :format => 'pdf', :name => 'cache_test', :cache_name => 'cache_test'
    assert_equal first_file_time, File.stat(@expected_path).mtime, "no expiry specified, cache should still be used"
    if Test::Unit::TestCase.is_windows?
      #windows needs files to be closed before the next action is performed.
      GC.start
    end
    get :give_me_expired, :format => 'pdf', :name => 'cache_test', :cache_name => 'cache_test'
    assert File.stat(@expected_path).mtime > first_file_time, "expiry specified, cache should not be used"
  end
  
  def test_should_include_correct_cache_backend
    TestController.caches_pdfs :storage => 's3'
    assert(TestController.pdf_storage.is_a?(Princely::Storage::S3Cache))

    TestController.caches_pdfs
    assert(TestController.pdf_storage.is_a?(Princely::Storage::FileCache))

  end
  
  private
  def setup_cache_test
    TestController.caches_pdfs :root_dir => cache_dir
    @expected_path = File.join(cache_dir, 'test', 'give_me', 'cache_test.pdf')
  end
  def cache_dir
    File.expand_path("#{File.dirname(__FILE__)}/../fixtures/pdf_test_cache")
  end
end
