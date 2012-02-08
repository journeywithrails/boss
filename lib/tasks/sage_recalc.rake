####### To add tasks to deploy/update, add them here and they will be called by the rightscript 
# "Sage rails svn code update & db config v1"

namespace :sage do
  namespace :invoices do
    desc "Task to recalc invoices"
    task :recalc => :environment do
      Invoice.find(:all).each{|i| 
#       puts('checking invoice ' + i.id.to_s)
        calculated_payment= i.paid
        if (i.paid_amount != calculated_payment )
          puts('recalculate invoice ' + i.id.to_s)
          puts('invoice cache paid amount is ' + i.paid_amount.to_s + ' but actual payment is ' + calculated_payment.to_s)
          i.save(false)
        end
      }
    end
  end
end