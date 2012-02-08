module LastObelus
  module Concurrency

    module Checkpoints
      module CheckpointAccessor
        def test_checkpoints
          #RAILS_DEFAULT_LOGGER.debug "----------------- test_checkpoints from #{ self.inspect[0, 30] }"
          @checkpoints ||= {}
        end

        def add_test_checkpoint(key, semaphore)
          semaphore.class.register_semaphore_ownership(self)
          self.test_checkpoints[key] = semaphore
        end
        
        def clear_checkpoints
          @checkpoints.clear
        end
        
        def set_test_checkpoint_source(obj)
          @checkpoints = obj.test_checkpoints rescue {}
        end

        def get_test_checkpoint_semaphor(key)
          sem = test_checkpoints[key] 
          if sem.nil? and defined?(self.class.test_checkpoints)
            sem = self.class.test_checkpoints[key]
          else
            sem
          end
        end

        if RAILS_ENV == 'test'
          def test_checkpoint_notify_and_wait(key)
            sem = get_test_checkpoint_semaphor(key)
            unless sem.nil?
              # RAILS_DEFAULT_LOGGER.debug "----------------- #{key} notify_and_wait #{ caller[0] }"
              sem.notify_and_wait
              # RAILS_DEFAULT_LOGGER.debug "----------------- #{key} notify_and_wait done"
            else
              # puts "no #{key} in #{self.test_checkpoints[key]} || #{self.class.test_checkpoints[key]}"
            end
          end
          def test_checkpoint_notify(key)
            sem = get_test_checkpoint_semaphor(key)
            unless sem.nil?
              # RAILS_DEFAULT_LOGGER.debug "----------------- #{key} notify #{ caller[0] }"
              sem.notify
              # RAILS_DEFAULT_LOGGER.debug "----------------- #{key} notify done"
            end
          end
          def test_checkpoint_wait(key)
            sem = get_test_checkpoint_semaphor(key)
            unless sem.nil?
              # RAILS_DEFAULT_LOGGER.debug "----------------- #{key} wait #{ caller[0] }"
              sem.wait
              # RAILS_DEFAULT_LOGGER.debug "----------------- #{key} wait done"
            end
          end
        else
          def test_checkpoints;end  
          def test_checkpoint_notify(key);end  
          def test_checkpoint_wait(key);end  
          def test_checkpoint_notify_and_wait(key);end  
        end
      end
        
      if RAILS_ENV == 'test' || $IN_MIGRATION
        # by doing this, a class has a different set of checkpoints than an instance of the class
        def self.included(base)
          base.extend CheckpointAccessor 
        end
      end

      include CheckpointAccessor

    end
  end
end

  
