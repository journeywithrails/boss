module Princely
  module Storage
    class S3Cache < Cache
      require 'aws/s3'
      include AWS::S3

      attr_reader :bucket_name, :s3_config

      def initialize(options={})          
        begin
          @s3_config_path = options[:s3_config_path] || File.join(RAILS_ROOT,'config','pdf_cache_s3.yml')
          @s3_config = YAML.load(ERB.new(File.read(@s3_config_path)).result)[RAILS_ENV].symbolize_keys
        rescue
          raise ConfigFileNotFoundError.new('File %s not found' % @s3_config_path)
        end

        @bucket_name = s3_config[:bucket_name]


      end
      
      def s3_object
        @s3_object = establish_connection!(s3_config.slice(:access_key_id, :secret_access_key, :server, :port, :use_ssl, :persistent, :proxy))        
      end
    end
  end
end