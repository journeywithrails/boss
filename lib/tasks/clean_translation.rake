# namespace :sage do
#   desc 'Remove text and pipe from translated strings'
#   task :clean_translation_files do
#     current_path = Dir.pwd
#     po_path = current_path + "/po/"
#     
#     dirs = []
#     dirs = Dir.entries(po_path)
#     dirs[0....3] = [] # RADAR remove . and .. and .svn
#     
#     dirs.each do |d|
#       language_dir = po_path + d + "/"
#       File.open("output.txt", "w") do |output|
#         File.foreach(language_dir + "billingboss.po") do |line|
#             line.gsub!(/(.*) "(.*)\|(.*)"/, "#{$1} \"#{$3}\"") if line.match(/msgstr/)
#             output << line
#           end
#         end
#       end
#     
#   end
# end

