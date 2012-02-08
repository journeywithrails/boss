namespace :test do
  Rake::TestTask.new(:acceptance => "db:test:prepare") do |t|
    t.libs << "test"
    t.pattern = 'test/acceptance/**/*_suite.rb'
    t.verbose = true
  end
  Rake::Task['test:acceptance'].comment = "Run the acceptance tests in test/acceptance. Requires a app server to be running on port 3000 on test environment"


  Rake::TestTask.new(:cross_stack => "db:test:prepare") do |t|
    t.libs << "test"
    t.pattern = 'test/cross_stack/**/*_test.rb'
    t.verbose = true    
  end
  Rake::Task['test:cross_stack'].comment = "Run acceptance tests against many applications"

  namespace :cross_stack do
    Rake::TestTask.new(:hello_world => "db:test:prepare") do |t|
      t.libs << "test"
      t.test_files = %w{test/cross_stack/bb_test.rb test/cross_stack/sbb_test.rb test/cross_stack/cas_test.rb test/cross_stack/csp/0001_csp_home_test.rb}
      t.verbose = true    
    end
    Rake::Task['test:cross_stack:hello_world'].comment = "Run signup/login acceptance tests with unstubbed CAS & SAM"


    Rake::TestTask.new(:simply => "db:test:prepare") do |t|
      t.libs << "test"
      t.pattern = 'test/cross_stack/simply/*_test.rb'
      t.verbose = true    
    end
    Rake::Task['test:cross_stack:simply'].comment = "Run simply integration tests with unstubbed CAS & SAM"
  end
  
  Rake::TestTask.new(:csp => "db:test:prepare") do |t|
    t.libs << "test"
    t.pattern = 'test/cross_stack/csp/*_test.rb'
    t.verbose = true    
  end
  Rake::Task['test:csp'].comment = "Run cross_stack acceptance tests against the customer service portal"
end

desc 'Measures test coverage'
  task :run_code_coverage do
    current_dir = Dir.pwd
    #dir=(build_artifacts.nil? ? "coverage" : "#{build_artifacts}/code_coverage")
    dir="#{current_dir}/code_coverage"
    if (File.directory?(dir))
      FileUtils.rm_r(dir)
    end
    system("mkdir \"#{dir}\"")      
   
    rcov = "rcov.cmd --rails --aggregate #{dir}/coverage.data -o #{dir} --text-summary -Ilib"
    
    system("#{rcov} --html test/unit/*_test.rb")
    system("#{rcov} --html test/functional/*_test.rb")
   end
  
  