####### To add tasks to deploy/update, add them here and they will be called by the rightscript 
# "Sage rails svn code update & db config v1"

namespace :sage do
  desc "Task to customize rightscale update/deployment"
  task :finish_deploy => ['sage:minify_js_files', 'sage:minify_css_files', 'sage:makemo'] do
    
  end
end
