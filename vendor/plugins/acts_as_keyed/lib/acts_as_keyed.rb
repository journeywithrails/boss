module LastObelus
  module Acts #:nodoc:
    module Keyed #:nodoc:
      def self.included(base)
        base.extend(ClassMethods)
      end

      module ClassMethods
        def acts_as_keyed(options = {})
          class_eval <<-EOV
            include LastObelus::Acts::Keyed::InstanceMethods
            
            has_many :access_keys, :as => :keyable
            
            def self.record_for_access_key(key)
              ak = AccessKey.find_by_key(key)
              ak.use? ? ak.keyable : nil
            end
          EOV
        end
      end

      module InstanceMethods
        def create_access_key(options={})
          ak = self.access_keys.create(options)
          ak.key
        end
        
        def access?(key)
          ak = access_keys.find(:first, :conditions => {:key => key})
          ak.use?
        end
        
        def get_or_create_access_key(options={})
          return self.create_access_key(options) if self.access_keys.nil? || self.access_keys.empty?
          if options.empty?
            key ||= self.access_keys.find(:first)
          else
            key ||= self.access_keys.find(:first, :conditions => options)
          end
          key = key.key if key # hah
          key ||= self.create_access_key(options)
          key
        end
        
      end 
    end
  end
end
