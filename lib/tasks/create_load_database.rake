require 'babel'

desc 'Create database for load testing and EmailPassword.txt for load testing'
  task (:create_load_database => :environment) do
    
    unless ENV.include?("users")
      raise "usage: rake create_load_database users=number"
    end
    num = ENV['users'].to_i

    # set the num constant to set the muliplier for adding records
    
    # num Users added
    
    # num Customers for each User, num * num Customers added
    
    # up to num Contacts for each Customer
    
    # num Invoices are added each Customer, num * num * num Invoices added
    # up to num Line Items are added per Invoice
    # invoice sent to random contact
      
    # Payment added for each Invoice, num * num * num Payments added
    
    puts "start populate load db with #{num} users"
    
    f = File.open("#{RAILS_ROOT}/test/load/EmailPassword.txt", "w")
    f.write("Email,Password\n")
    
    # create first to last range of users 
    num.times {
      u = User.new()
      u.create_biller
      u.login = Babel.random_username + "@" + Babel.random_username + ".com"
      u.password = "test"
      u.password_confirmation = "test"
      u.terms_of_service = "1"
      u.save
      
      f.write("#{u.login},test\n")
    }
    
    f.close    
    
    puts "after add users"
    
    # create first to last range customers for each user
    User.find(:all).each { |u|
      num.times { 
        c = u.customers.build
        c.name = Babel.random_short.gsub( '&', 'and' )
        c.address1 = "address 1"
        c.address2 = "address 2"
        c.city = "city"
        c.province_state = "British Columbia"
        c.postalcode_zip = "V6V 1C2"
        c.country = "Canada"
        c.website = "website"
        c.phone = "555-1212"
        c.fax = "555-1313"
        c.save
      }
    }
    
    puts "after add customers"
    
    # create first to last range contacts for each customer
    Customer.find(:all).each { |c| 
      (rand(num) + 1).times { 
        ct = c.contacts.build
        ct.first_name = Babel.random_male_name
        ct.last_name = Babel.random_surname
        ct.email = Babel.random_username + "@" + Babel.random_username + ".com"
        ct.save
      }
    }
    
    puts "after add contacts"
    
    # Create first to last range of invoice for each customer for each user
    User.find(:all).each { |u|
      Customer.find(:all, :conditions => ["created_by_id = ?", u.id]).each { |c| 
        num.times { 
          days = rand(90)
          params = {
            "unique"=>rand(999999999) + 1,
            "date"=>Time.now() - days * 24 * 60 * 60, 
            "reference"=>"", 
            "customer_id"=>c.id.to_s, 
            "contact_id"=>c.contacts[rand(c.contacts.length - 1)].id.to_s, 
            "discount_type"=>"percent", 
            "due_date"=>Time.now() - days * 24 * 60 * 60 + 30 * 24 * 60 * 60, 
            "discount_value"=>"", 
            "description"=>""
          } 
          
          inv = u.invoices.build
          inv.attributes = params
          inv.save      
          
          (rand(num) + 1).times { 
            inv.line_items.create({:quantity => BigDecimal.new((rand(num) + 1).to_s), 
                                   :price => BigDecimal.new((rand(num) + 1).to_s),
                                   :unit => Babel.random_short.gsub( '&', 'and' ),
                                   :description => Babel.random_short.gsub( '&', 'and' )})
          }
          inv.save
        }
      }
    }
    
    puts "after add invoices"
    
    # create payments
    Invoice.find(:all).each { |inv|
    
      amt = inv.amount_owing  
      inv_status = inv.unique.to_i.modulo(4)
    
      case inv_status
      when 0:    
        if amt != 0 
          inv.mark_sent!
          params = {
            "pay_type"=>"cheque",   
            "date"=>"2008-04-03",
            "amount"=>amt,     
            "description"=>"Payment Description", 
            "customer_id"=>inv.customer_id
          }
          
          u = inv.created_by
          p = u.payments.build(params)
          p.save_and_apply(inv)
        end    
      when 1:    
        if amt != 0 
          inv.mark_sent!
          params = {
            "pay_type"=>"cheque",   
            "date"=>"2008-04-03",
            "amount"=>amt - 0.01,     
            "description"=>"Payment Description", 
            "customer_id"=>inv.customer_id
          }
          
          u = inv.created_by
          p = u.payments.build(params)
          p.save_and_apply(inv)
        end
      when 2:
        if amt != 0 
          inv.mark_sent!
        end        
      else          
        
      end
    }  
    
    puts "finish populate load db"
    
   
   end