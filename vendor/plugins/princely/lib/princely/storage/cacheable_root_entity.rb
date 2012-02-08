module Princely
  module Storage
    module CacheableRootEntity
      def pdf_cache_dir
        raise StandardError, 'cachable entity must be a user' if self.respond_to?(:created_by)
        raise StandardError, 'cachable entity must be saved' if self.new_record?

        File.join(
          File.join(RAILS_ROOT, 'public', 'pdf'),
          'users',
          ("%08d" % self.id).scan(/..../)
        )
      end

      def pdf_dirty_cache
        FileUtils::rm_rf(self.pdf_cache_dir, :secure => true)
      end

    end
  end
end