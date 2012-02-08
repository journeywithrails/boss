module Princely
  module Storage
    class Cache
      def self.pdf_cache_root_dir
        File.join(RAILS_ROOT, 'public', 'pdf')
      end
    end
  end
end