module Sage
  module ActiveRecord
    module Validations
      module ValidatesExclusivityOf
        def validates_exclusivity_of(*attr_names)
          configuration = { :message => "", 
                            :on => :save,
                            :allow_nil => true,
                            :allow_blank => true,
                            :allow_zero => false }
          configuration.update(attr_names.extract_options!)
          configuration[:message] = "only one of #{attr_names.join(', ')} may be set"
      
          validates_each(attr_names, configuration) do |record, attr_name, value|
            did_error = false
            unless did_error
              unless configuration[:allow_zero] and (value == 0)
                unless attr_names.reject{|a| a == attr_name}.all?{|attr| record.send(attr).nil? or 
                                    (configuration[:allow_blank] and record.send(attr).blank? ) or 
                                    (configuration[:allow_zero] and record.send(attr) == 0) } then
              
                  record.errors.add_to_base(configuration[:message]) unless did_error
                  did_error = true
                end
              end
            end
          end
        end
      end
    end
  end
end


ActiveRecord::Base.class_eval do
  extend Sage::ActiveRecord::Validations::ValidatesExclusivityOf
end