require 'test/unit'
require 'fileutils'
require 'ftools'
require 'win32screenshot'
require 'RMagick'

require File.dirname(__FILE__) + '/acceptance_test_helper'

#include Watir::ScreenCapture
include Magick

#override TestCase so that we can put in our own error handler when tests fail
class SageWindowsAccepTestCase < Test::Unit::TestCase
  
  def initialize(test_method_name)
    super(test_method_name)
  end
  
  def default_test    
  end

if (ENV['CC_BUILD_ARTIFACTS'].nil?)
  def self.suite 
     s = super 
     
     def s.setup_suite_test

       if ($external_browser_instance.nil?)
         $external_browser_instance = SageTestSession.create_browser()
         $suite_created_browser = true
       end
     end 
     
     def s.teardown_suite_test

       if ($suite_created_browser) then
         if (!$external_browser_instance.nil?)
           $external_browser_instance.close
           $external_browser_instance = nil
         end
       end
       
     end 
     
     def s.run(*args) 
       setup_suite_test
       super 
       teardown_suite_test
     end 
     s 
  end 
end

  #used for capture screens   
  #use class_name and test_case_method_name to generate the image file name
  def save_image(class_name, test_case_method_name)
    if (WatirBrowser.ie?)
       #see if CC_BUILD_ARTIFACTS is set, used by cruise control server
       build_artifacts_folder =  ENV['CC_BUILD_ARTIFACTS']
       if (not build_artifacts_folder.nil?)
         build_artifacts_folder = build_artifacts_folder.gsub("/", "\\")
       end
       #if not set, see if TORNADO_TEST_IMAGE is set
       #developer can set this if they want to capture the images on their own machine
       if (build_artifacts_folder.nil?)
         build_artifacts_folder = ENV['TORNADO_TEST_IMAGE']
       end
       
#       build_artifacts_folder = "c:\\railsproject"
       unless (build_artifacts_folder.nil?)

         file_name = build_artifacts_folder+ "\\" + class_name + "-" + test_case_method_name.to_s  + ".png"
         
         if (File.exists?(file_name)) 
           FileUtils.rm(file_name)
         end
   
        begin

         width, height, bitmap = Win32::Screenshot.desktop
         img = Magick::Image.from_blob(bitmap)[0]
         img.write(file_name)
       rescue Magick::ImageMagickError => e
         puts("cannot capture screen. Exception is " + e.message)
        end
                         
 #        @screen_capture = Watir::ScreenCapture
 #        @screen_capture.screen_capture(file_name, false, false)         
      end
    end
  end
     
  def add_failure(message, all_locations=caller())    
    save_image(self.class.name, @method_name)     
    super(message, all_locations)
  end
  
  def add_error(exception)
    save_image(self.class.name, @method_name)     
    super(exception)
  end
end