module LastObelus
  module ActiveSupport #:nodoc:
    module CoreExtensions #:nodoc:
      module Numeric #:nodoc:
        module BusinessDaysAgo
          def business_days_ago
            num = self
            t=Time.now
            while (num > 0) do
              t -= 1.day
              num -=1 unless t.wday==0 or t.wday==6 
            end
            t
          end
        end
      end
    end
  end
end

Numeric.class_eval { include LastObelus::ActiveSupport::CoreExtensions::Numeric::BusinessDaysAgo }