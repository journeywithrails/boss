require File.dirname(__FILE__) + '/../test_helper'

class LogoTest < ActiveSupport::TestCase
  # Replace this with your real tests.
unless ENV['OFFLINE'] # skip if offline
    def test_valid_only_if_image_exists
      logo = Logo.new
      logo.uploaded_data = uploaded_file(file_path("missing_image.gif"), "image/gif", "missing_image.gif")    
      assert logo.save
      partitioned_id = ("%08d" % logo.id).scan(/..../).join("/")
      assert_equal "/logos/0000/0003/missing_image.gif", logo.public_filename
      assert logo.valid?
      assert logo.image?
    rescue SocketError
      # offline
    end
end # skip if offline
  
  private

  def assert_equal_paths(expected_path, path)
    assert_equal normalize_path(expected_path), normalize_path(path)
  end


  def normalize_path(path)
    Pathname.new(path).realpath
  end

  def file_path(filename)
    File.expand_path("#{File.dirname(__FILE__)}/../fixtures/files/#{filename}")
  end

  def uploaded_file(path, content_type, filename, type=:tempfile) # :nodoc:
    if type == :tempfile
      t = Tempfile.new(File.basename(filename))
      FileUtils.copy_file(path, t.path)
    else
      if path
        t = StringIO.new(IO.read(path))
      else
        t = StringIO.new
      end
    end
    (class << t; self; end).class_eval do
      alias local_path path if type == :tempfile
      define_method(:local_path) { "" } if type == :stringio
      define_method(:original_filename) {filename}
      define_method(:content_type) {content_type}
    end
    return t
  end
  
end
