module Sage
  module ActiveMerchant
    module FilterCreditCard
      # Filter out credit card information from logs in production mode,
      # in case an account.inspect gets logged. PCI compliance.
      # Attributes can still be accessed individually.
      def inspect
        return super if RAILS_ENV!='production'
        attr_list = []
        attrs = (defined? instance_values and not instance_values.nil?) ? instance_values : {}
        attrs.each_pair do |name, value|
          if name == "number"
            #show only last 4 digits of ccard
            filtered_value = '"' + ('x'*(value.length-4) + value[-4,4]) + '"'
          elsif value.nil? or not value.respond_to?(:to_s)
            filtered_value = value.inspect
          else
            filtered_value = "\"#{value.to_s}\""
          end
          
          attr_list << "@#{name}=#{filtered_value}"
        end
        "\#<#{self.class.name} #{attr_list.join(', ')}>"
      end
    end
  end
end

::ActiveMerchant::Billing::CreditCard.send(:include, ::Sage::ActiveMerchant::FilterCreditCard)
