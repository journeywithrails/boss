module Sage
  module ActiveRecord
    module Validations
      module ValidatesNotNegative
        def validates_not_negative(*attr_names)
          configuration = { :message => ::ActiveRecord::Errors.default_error_messages[:invalid], :on => :save }
          configuration.update(attr_names.extract_options!)

          validates_each(attr_names, configuration) do |record, attr_name, value|
            record.errors.add(attr_name, configuration[:message]) if value && value.to_f < 0
          end
        end
      end
    end
  end
end


ActiveRecord::Base.class_eval do
  extend Sage::ActiveRecord::Validations::ValidatesNotNegative
end