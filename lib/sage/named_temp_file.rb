require 'tempfile'

module Sage
  class NamedTempFile < Tempfile
    # Close the temp file but don't unlink it so that an external program can use it.
    def hold
      @tmpfile.close if @tmpfile
      @tmpfile = nil
      @tmpname
    end
  end
end
