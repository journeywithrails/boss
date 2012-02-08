module Princely
  module Storage
    module CacheableEntity
      def pdf_cache_dir
        raise StandardError, 'cachable entity must belong to user' unless self.created_by

        File.join(
          File.join(RAILS_ROOT, 'public', 'pdf'),
          'users',
          ("%08d" % self.created_by_id).scan(/..../),
          self.class.name.tableize,
          self.id_partitioned[0]
        )
      end

      def id_partitioned
        ("%08d" % self.id).scan(/..../)
      end

      def pdf_cache_name
        self.id_partitioned[1] + '.pdf'
      end

      def pdf_cache_path
        File.join(self.pdf_cache_dir, self.pdf_cache_name)
      end

      def pdf_dirty_cache
        FileUtils::rm_rf(self.pdf_cache_dir, :secure => true)
        true
      end
    end
  end
end