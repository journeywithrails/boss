require 'fileutils'
include FileUtils

#minify either css or js files
#rake minify_resource_files RESOURCE_EXT=js
#or rake minify_resource_files RESOURCE_EXT=css
namespace :sage do
  task :minify_js_files do
    Rake.application.minify_resource_files "js", "javascripts"  
  end

  task :minify_css_files do
    Rake.application.minify_resource_files "css", "themes"  
    Rake.application.minify_resource_files "css", "stylesheets"  
  end
end



Rake::TaskManager.class_eval do
  
  def minify_resource_files(file_ext, parent_folder)
     current_dir = Dir.pwd

     public_dir =  current_dir + "/public/#{parent_folder}"
     #store temp files here
     build_temp_dir = current_dir + "/public/tmp_build"
     dest_dir = public_dir + "/build"

     FileUtils.remove_dir(dest_dir, true)     
     FileUtils.remove_dir(build_temp_dir, true)
     FileUtils.mkdir(build_temp_dir)  

     FileUtils.cp_r(public_dir, build_temp_dir)

    # cmd = "java -jar " + current_dir + "/yuicompressor-2.3.4/build/yuicompressor-2.3.4.jar --nomunge"  
    cmd = "ruby script/jsmin.rb <"  

    Rake.application.minify_files_in_folder(cmd, build_temp_dir, file_ext)

    FileUtils.mv(build_temp_dir+"/#{parent_folder}", dest_dir)    
    FileUtils.remove_dir(build_temp_dir, true) 

  end
  
  
  #helper method to minify all files in the folder or child folders
  def minify_files_in_folder(cmd, folder_name, file_ext)

    error_str = ""
    count = 0
    file_count = 0
        
    FileUtils.rm Dir.glob("#{folder_name}/*-min#{file_ext}")
    d = Dir.new(folder_name)      
    d.each  { |file_name|
      if (File.directory?(folder_name + "/" + file_name))
        if (file_name != "." && file_name != ".." && file_name !=".svn")
          minify_files_in_folder(cmd, folder_name+"/"+file_name, file_ext)
        end
      elsif (file_name.include?(file_ext))
        file_count = file_count + 1
        full_name = folder_name + "/" + file_name
        full_cmd = cmd + " " + full_name + " > " + full_name.sub(file_ext, "-min#{file_ext}")
        sh(full_cmd) 

        if (File.exists?(full_name))
          count = count + 1
          FileUtils.mv(full_name.sub(file_ext, "-min#{file_ext}"), full_name)
        else
          error_str =  error_str + "Error: #{file_name} not minified.\r\n"
        end
      end
    }
    if (file_count != count)
      raise("#{file_count} files found in #{folder_name}. #{count} files minified." + error_str)
      
    end
    if (file_count != 0)
      puts("#{file_count} files found in #{folder_name}. #{count} files minified.")       
    end
  end
end
