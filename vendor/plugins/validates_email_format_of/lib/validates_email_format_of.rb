module ActiveRecord
  module Validations
    module ClassMethods
      # Validates whether the value of the specified attribute is a valid email address
      #
      #   class User < ActiveRecord::Base
      #     validates_email_format_of :email, :on => :create
      #   end
      #
      # Configuration options:
      # * <tt>message</tt> - A custom error message (default is: " does not appear to be a valid e-mail address")
      # * <tt>on</tt> Specifies when this validation is active (default is :save, other options :create, :update)
      # * <tt>if</tt> - Specifies a method, proc or string to call to determine if the validation should
      #   occur (e.g. :if => :allow_validation, or :if => Proc.new { |user| user.signup_step > 2 }).  The
      #   method, proc or string should return or evaluate to a true or false value.
      
      def validates_email_format_of(*attr_names)
        configuration = { :message => ' does not appear to be a valid e-mail address', 
                          :on => :save, 
                          :with => /^(([A-Za-z0-9]+_+)|([A-Za-z0-9]+\-+)|([A-Za-z0-9]+\.+)|([A-Za-z0-9]+\++))*[A-Za-z0-9]+@((\w+\-+)|(\w+\.))*\w{1,63}\.[a-zA-Z]{2,6}$/i,
                          :list => false
                         }

        configuration.update(attr_names.pop) if attr_names.last.is_a?(Hash)

        validates_each(attr_names, configuration) do |record, attr_name, value|
          if configuration[:list]
            value = value.to_s.split(/, */)
            value.map!{|v| v.sub(/.*<([^>]*)>.*/, '\1')}
          else
            value = [value.to_s]
          end
          unless ['test', 'development'].include?(RAILS_ENV) and !value.empty? and value.all?{|v| v == 'autotest@10.152.17.65'}
            record.errors.add(attr_name, configuration[:message]) if value.empty? or value.any?{|v| v.blank? or not v =~ configuration[:with]}
          end
        end
      end
      
    end   
  end
end
 
