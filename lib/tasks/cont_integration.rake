

require 'fileutils'
include FileUtils
 
desc "Run all unit, functional, and integration tests"
Rake::TestTask.new(:cont_integration_unit_test) do |t|
    t.libs << "test"
    t.test_files = FileList['test/{functional,unit,integration}/*_test.rb']
    t.verbose = true
end

#dependencies
 task :prepare_test_environment do
  ENV['RAILS_ENV'] = 'test'
  current_dir = Dir.pwd
  


  #use it's own database configuration
  if File.exists?(current_dir + "/config/database.yml")   
    #copy database.yml
    File.delete current_dir + "/config/database.yml"
  end
  cp current_dir + "/config/database.contintegration.yml", Dir.pwd + "/config/database.yml"
  
  sh('rake db:migrate')

  sh('rake db:test:prepare')
  
  #run makemo in a shell and strip out warnings from stderr
  sh('rake sage:makemo 2>&1 | grep -v Warning - |grep -v Done. | grep -v msgid - | grep -v msgstr - | grep -v "#~ \"" -')
  
end

#prepare test environment

task :cont_integration_unit_test => [:prepare_test_environment]
task :cont_integration_accep_test => [:prepare_test_environment]

Rake::TestTask.new(:cont_integration_accep_test) do |t|
  t.test_files = FileList['test/acceptance/*_test.rb']
  t.verbose = false
end


desc 'Measures test coverage'
  task :run_coverage do
    #rm_f "coverage"
    build_artifacts=ENV['CC_BUILD_ARTIFACTS']
    #dir=(build_artifacts.nil? ? "coverage" : "#{build_artifacts}/code_coverage")
    dir="#{build_artifacts}/code_coverage"
    system("mkdir \"#{dir}\"")
    rcov = "rcov.cmd --rails --aggregate #{dir}/coverage.data -o #{dir} --text-summary -Ilib"
    
    system("#{rcov} --html test/unit/*_test.rb")
    system("#{rcov} --html test/functional/*_test.rb")
#    system("#{rcov} --html test/integration/*_test.rb")      
  end


##################### acceptance test settings #######################33
if ENV['RAILS_WINDOWS']
  
require "win32/service"
include Win32

desc 'prepare environment for accep test'
task :prepare_accep_test_environment do
  #shut down the testing server that is running
  status = Service.status("tornado-test")
  need_to_start = true
 # stop the server if it is running
  if (status.current_state == "running")
    Service.stop("tornado-test")
  end
  
  current_dir = Dir.pwd
  
  if File.exists?(current_dir + "/config/database.yml")   
    #copy database.yml
    File.delete current_dir + "/config/database.yml"
  end
  #File.copy current_dir + "/config/database.accep.yml", Dir.pwd + "/config/database.yml"    
  args = [current_dir + "/config/database.accep.yml", Dir.pwd + "/config/database.yml"]
  File.send("copy" , *args)
  
  #copy the current source code to the deploy folder
  FileUtils.rm_r "C:/tornadodeploy", :force => true  
  FileUtils.cp_r current_dir, "C:/tornadodeploy"
  puts("coping files to C:/tornadodeploy")
  Service.start("tornado-test")  
  
  sh(current_dir + "/cont_integration/preparedata.bat")
  
  if ENV['COMPUTERNAME'] == 'INNOV-BUILD'
    `taskkill /f /im iexplore.exe`
  end

end

desc 'prepare environment for accep test running in remote machines'
task :prepare_accep_test_environment_remote do
  #shut down the testing server that is running
  current_dir = Dir.pwd
  
  if File.exists?(current_dir + "/config/database.yml")   
    #copy database.yml
    File.delete current_dir + "/config/database.yml"
  end
  File.copy current_dir + "/config/database.accep.yml", Dir.pwd + "/config/database.yml"  
  
  #deploy to remote server
  sh("cap.cmd deploy")  
end

#, "db:migrate", "db:test:purge", "db:test:prepare"
# task :cont_integration_accep_test => [:prepare_accep_test_environment, "db:migrate", "db:test:purge", "db:test:prepare"]
task :cont_integration_accep_test => [:prepare_accep_test_environment]

end
