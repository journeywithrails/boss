# Run a selection of tests
#
# Edit this task to run tests relevant to what you're working on.
#
# Preferably run with snailgun to remove overhead of loading
# Rails env and plugins every time.
#
# With snailgun enabled and a small subset of tests I get down to 
# 5 seconds, which enables me to do something close to TDD

namespace :test do

  # db:test:prepare takes too long
  #Rake::TestTask.new(:sel => "db:test:prepare") do |t|
    
  Rake::TestTask.new(:sel) do |t|
    ENV['RAILS_ENV'] = 'test'
    t.libs << "test"
    #t.verbose = true
    
    # 1. Select test files
    
      # explicitly select test files - fastest
       t.test_files = %w[
         test/functional/invoices_controller_test.rb
       ]

      # Load all functional, unit and integration test files
      # FIXME: the tests fail if loaded in different order
      # t.pattern = %w(
      #   test/integration/**/*_test.rb
      #   test/functional/**/*_test.rb
      #   test/unit/**/*_test.rb
      # )

    # 2. Now (optionall) filter names of specific tests
    #    you'd like to run.
    
      # run single test
      # t.options = "--name=test_should_send_invoice_copy_to_user"
      
      # run all tests that match a regexp
      # t.options = %w[ --name=/delivery/ ]
      
      # explicitly list test names (from any loaded file)
      names = %w(
      test_should_edit_invoice_using_original_gst_in_taxable_amount
      )
      t.options = names.map{|n| "--name=#{n}" }.join(" ")

  end
  Rake::Task['test:sel'].comment = "Run a selection of tests - for use with snailgun"

end
