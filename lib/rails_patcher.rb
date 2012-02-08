module Rails
  module Patcher
    ROOT_DIR = File.join(File.dirname(__FILE__), '..')
    PATCHES_DIR = "#{ROOT_DIR}/lib/patches/" 

    def self.run
      `mkdir #{PATCHES_DIR}` unless File.directory?(PATCHES_DIR)
      `rake rails:freeze:gems` unless File.directory?("#{ROOT_DIR}/vendor/rails")

      Dir["#{PATCHES_DIR}/*"].each do |file|
        next if %w(. ..).include?(file) || file =~ /^APPLIED_/
        STDERR.print "Patching #{file}..." 
        `patch -d #{ROOT_DIR}/vendor/rails -p0 < #{PATCHES_DIR}/#{file}`
        STDERR.print "Done.\n" 
        `mv #{PATCHES_DIR}/#{file} #{PATCHES_DIR}/APPLIED_#{file}`
      end
    end
  end
end